import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart' show rootBundle;
import '../../data/domain/models/frame_data.dart';
import '../../data/runtime/models/detection_model.dart';
import 'inference_isolate.dart';

class TFLiteService {
  Isolate?  _isolate;
  SendPort? _isolateSendPort;
  final ReceivePort _receivePort = ReceivePort();
  bool _modelLoaded = false;

  int detectionOutputSize = 0;
  int maskProtoSize       = 0;

  Future<void> loadModel() async {
    final responses = _receivePort.asBroadcastStream();

    print('[TFLiteService] Spawning isolate...');
    _isolate = await Isolate.spawn(inferenceIsolateEntry, _receivePort.sendPort);
    print('[TFLiteService] Isolate spawned');

    _isolateSendPort = await responses.first;
    print('[TFLiteService] Received SendPort from isolate');

    final modelData  = await rootBundle.load('assets/models/yolov8_lane_seg.tflite');
    final modelBytes = modelData.buffer.asUint8List();
    print('[TFLiteService] Model bytes length: ${modelBytes.length}');

    final loadReply = ReceivePort();
    _isolateSendPort!.send([0, modelBytes, loadReply.sendPort]);   // tag 0 = load

    final response = await loadReply.first;
    loadReply.close();

    if (response is Map) {
      if (response.containsKey('error')) {
        throw Exception('Model load failed: ${response['error']}');
      }
      detectionOutputSize = response['detSize'] as int;
      maskProtoSize       = response['maskSize'] as int;
      print('[TFLiteService] Model loaded. detSize=$detectionOutputSize maskSize=$maskProtoSize');
    }
    _modelLoaded = true;
  }

  Future<List<DetectionModel>> predict(FrameData frame) async {
    if (!_modelLoaded || _isolateSendPort == null) {
      throw StateError('Model not loaded');
    }

    final replyPort = ReceivePort();
    _isolateSendPort!.send([1, frame, replyPort.sendPort]);   // tag 1 = inference

    final result = await replyPort.first;
    replyPort.close();

    if (result is List<DetectionModel>) return result;
    if (result is Map && result.containsKey('error')) {
      throw Exception('Inference error: ${result['error']}');
    }
    throw Exception('Unexpected response: $result');
  }

  void dispose() {
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);
  }
}