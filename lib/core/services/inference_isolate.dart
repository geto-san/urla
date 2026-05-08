import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../data/domain/models/frame_data.dart';
import '../ml/yolo_decoder.dart';

void inferenceIsolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  Interpreter? interpreter;
  final decoder = YoloSegDecoder();
  int numAttrs = 0, numAnchors = 0;

  receivePort.listen((message) async {
    if (message is List && message.isNotEmpty) {
      final tag = message[0];

      // ── Load model ──
      if (tag == 0 && message.length == 3) {
        try {
          final modelBytes = message[1] as Uint8List;
          final replyPort = message[2] as SendPort;

          // Try GPU delegate first; fall back to CPU if unavailable.
          Interpreter? gpuInterpreter;
          try {
            final gpuDelegate = GpuDelegateV2(
              options: GpuDelegateOptionsV2(isPrecisionLossAllowed: true),
            );
            gpuInterpreter = Interpreter.fromBuffer(
              modelBytes,
              options: InterpreterOptions()..addDelegate(gpuDelegate),
            );
            print('[ISOLATE] GPU delegate loaded successfully');
          } catch (e) {
            print('[ISOLATE] GPU delegate unavailable, falling back to CPU: $e');
            gpuInterpreter = null;
          }

          interpreter = gpuInterpreter ??
              Interpreter.fromBuffer(
                modelBytes,
                options: InterpreterOptions()..threads = 4,
              );
          interpreter!.allocateTensors();

          final detShape  = interpreter!.getOutputTensor(0).shape;   // [1,39,8400]
          final maskShape = interpreter!.getOutputTensor(1).shape;   // [1,160,160,32]
          numAttrs   = detShape[1];
          numAnchors = detShape[2];

          replyPort.send({
            'detSize':  numAttrs * numAnchors,
            'maskSize': maskShape[1] * maskShape[2] * maskShape[3],
            'detShape': detShape,
            'maskShape': maskShape,
          });
        } catch (e) {
          (message[2] as SendPort).send({'error': e.toString()});
        }
      }

      // ── Inference ──
      else if (tag == 1 && message.length == 3) {
        try {
          final frame     = message[1] as FrameData;
          final replyPort = message[2] as SendPort;

          if (interpreter == null) {
            replyPort.send({'error': 'Model not ready'});
            return;
          }

          // 1. Letterbox preprocessing
          final (tensor, scale, dx, dy) = _preprocessLetterbox(frame);
          final shaped = tensor.reshape([1, 640, 640, 3]);

          // 2. Tell the decoder how to un‑transform coordinates
          decoder.setPreprocessParams(scale, dx, dy);

          // 3. Allocate output containers
          final detOut = List.generate(1, (_) =>
              List.generate(numAttrs, (_) => List<double>.filled(numAnchors, 0.0)));
          final maskOut = List.generate(1, (_) =>
              List.generate(160, (_) =>
                  List.generate(160, (_) => List<double>.filled(32, 0.0))));

          interpreter!.runForMultipleInputs([shaped], {0: detOut, 1: maskOut});

          // 4. Flatten tensors for decoder
          final detFlat = Float32List(numAttrs * numAnchors);
          int idx = 0;
          for (int a = 0; a < 1; a++) {
            for (int b = 0; b < numAttrs; b++) {
              for (int c = 0; c < numAnchors; c++) {
                detFlat[idx++] = detOut[a][b][c];
              }
            }
          }

          final maskFlat = Float32List(160 * 160 * 32);
          idx = 0;
          for (int a = 0; a < 1; a++) {
            for (int b = 0; b < 160; b++) {
              for (int c = 0; c < 160; c++) {
                for (int d = 0; d < 32; d++) {
                  maskFlat[idx++] = maskOut[a][b][c][d];
                }
              }
            }
          }

          // 5. Decode (coordinates are now in original image space)
          final detections = decoder.decode([detFlat, maskFlat], 0.4);
          replyPort.send(detections);   // simply the list

        } catch (e, st) {
          print('[ISOLATE] Inference error: $e\n$st');
          (message[2] as SendPort).send({'error': '$e\n$st'});
        }
      }
    }
  });
}

/// Letterbox preprocessing: resizes preserving aspect ratio and pads to 640×640.
/// Returns (tensor, scale, dx, dy) where `scale` is the scale factor from original
/// image to the resized part, and `(dx,dy)` is the top‑left padding offset.
(Float32List tensor, double scale, double dx, double dy) _preprocessLetterbox(FrameData frame) {
  const int inputSize = 640;
  final original = img.Image.fromBytes(
    width: frame.width,
    height: frame.height,
    bytes: frame.bytes.buffer,
    order: img.ChannelOrder.rgb,
  );

  final double scale = math.min(inputSize / original.width, inputSize / original.height);
  final int newW = (original.width * scale).round();
  final int newH = (original.height * scale).round();

  final resized = img.copyResize(original, width: newW, height: newH,
      interpolation: img.Interpolation.linear);

  // Black canvas
  final canvas = img.Image(width: inputSize, height: inputSize);
  img.fill(canvas, color: img.ColorRgb8(0, 0, 0));

  final int dx = (inputSize - newW) ~/ 2;
  final int dy = (inputSize - newH) ~/ 2;
  img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

  final tensor = Float32List(inputSize * inputSize * 3);
  int index = 0;
  for (int y = 0; y < inputSize; y++) {
    for (int x = 0; x < inputSize; x++) {
      final pixel = canvas.getPixel(x, y);
      tensor[index++] = pixel.r / 255.0;
      tensor[index++] = pixel.g / 255.0;
      tensor[index++] = pixel.b / 255.0;
    }
  }

  return (tensor, scale, dx.toDouble(), dy.toDouble());
}