import 'dart:typed_data';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../data/runtime/models/preprocess_task.dart';   // RawPreprocessTask
import '../../data/runtime/models/detection_model.dart';
import '../ml/yolo_decoder.dart';
import 'preprocess_isolate.dart';

class TFLiteService {
  late Interpreter _interpreter;
  final PreprocessIsolate _preprocessIsolate = PreprocessIsolate();

  // Output buffer sizes (set after model load)
  late int detectionOutputSize;
  late int maskProtoSize;

  Future<void> loadModel() async {
    await _preprocessIsolate.start();

    _interpreter = await Interpreter.fromAsset(
      'assets/models/yolov8_lane_seg.tflite',
      options: InterpreterOptions()..threads = 4,
    );
    _interpreter.allocateTensors();

    final detShape = _interpreter.getOutputTensor(0).shape;   // e.g., [1, N, 42]
    final maskShape = _interpreter.getOutputTensor(1).shape; // e.g., [1, 32, 160, 160]

    detectionOutputSize = detShape[1] * detShape[2];  // N * 42
    maskProtoSize = maskShape[1] * maskShape[2] * maskShape[3]; // 32*160*160

    print('Detection output size: $detectionOutputSize floats');
    print('Mask proto size: $maskProtoSize floats');
  }

  /// Run inference on a raw camera frame.
  /// [task] contains YUV planes, width, height, and strides.
  Future<List<DetectionModel>> predict(RawPreprocessTask task) async {
    // Preprocessing (YUV→RGB, resize, normalise) runs in the background isolate
    final Float32List tensor = await _preprocessIsolate.process(task);

    // Prepare input and output tensors
    final input = [tensor];
    final detOutput = Float32List(detectionOutputSize);
    final maskOutput = Float32List(maskProtoSize);
    final outputMap = {0: detOutput, 1: maskOutput};

    // Run model
    _interpreter.runForMultipleInputs(input, outputMap);

    // Decode
    final decoder = YoloSegDecoder();
    return decoder.decode([detOutput, maskOutput], 0.4);
  }

  void dispose() {
    _preprocessIsolate.dispose();
    _interpreter.close();
  }
}