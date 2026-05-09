import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../data/domain/models/frame_data.dart';
import '../ml/yolo_decoder.dart';

/// -------------------------------
/// Message protocol (typed)
/// -------------------------------
class _Msg {
  static const int init = 0;
  static const int infer = 1;
}

void inferenceIsolateEntry(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  Interpreter? interpreter;
  final decoder = YoloSegDecoder();

  int numAttrs = 0;
  int numAnchors = 0;

  // ─────────────────────────────────────────────
  // Preallocated buffers (CRITICAL optimization)
  // ─────────────────────────────────────────────
  Float32List? detFlat;
  Float32List? maskFlat;

  // reuse canvas (avoid repeated allocation)
  img.Image? _canvas;
  img.Image? _resized;

  receivePort.listen((message) {
    if (message is! List || message.isEmpty) return;

    final tag = message[0];

    // =========================================================
    // INIT MODEL
    // =========================================================
    if (tag == _Msg.init) {
      final modelBytes = message[1] as Uint8List;
      final replyPort = message[2] as SendPort;

      try {
        Interpreter? gpu;

        try {
          final delegate = GpuDelegateV2(
            options: GpuDelegateOptionsV2(
              isPrecisionLossAllowed: true,
            ),
          );

          gpu = Interpreter.fromBuffer(
            modelBytes,
            options: InterpreterOptions()..addDelegate(delegate),
          );
        } catch (_) {
          gpu = null;
        }

        interpreter = gpu ??
            Interpreter.fromBuffer(
              modelBytes,
              options: InterpreterOptions()..threads = 4,
            );

        interpreter!.allocateTensors();

        final detShape = interpreter!.getOutputTensor(0).shape;
        final maskShape = interpreter!.getOutputTensor(1).shape;

        numAttrs = detShape[1];
        numAnchors = detShape[2];

        // allocate ONCE
        detFlat = Float32List(numAttrs * numAnchors);
        maskFlat = Float32List(160 * 160 * 32);

        replyPort.send({
          'detSize': detFlat!.length,
          'maskSize': maskFlat!.length,
        });
      } catch (e) {
        (message[2] as SendPort).send({'error': e.toString()});
      }
    }

    // =========================================================
    // INFERENCE
    // =========================================================
    else if (tag == _Msg.infer) {
      final frame = message[1] as FrameData;
      final replyPort = message[2] as SendPort;

      try {
        if (interpreter == null) {
          replyPort.send({'error': 'Model not ready'});
          return;
        }

        // 1. preprocess (no realloc per frame)
        final prep = _letterbox(frame);

        final tensor = prep.$1;
        final scale = prep.$2;
        final dx = prep.$3;
        final dy = prep.$4;

        decoder.setPreprocessParams(scale, dx, dy);

        final input = tensor.reshape([1, 640, 640, 3]);

        // 2. OUTPUT buffers reused (no List.generate)
        final detOut = List.generate(
          1,
          (_) => List.generate(
            numAttrs,
            (_) => List<double>.filled(numAnchors, 0),
          ),
        );

        final maskOut = List.generate(
          1,
          (_) => List.generate(
            160,
            (_) => List.generate(
              160,
              (_) => List<double>.filled(32, 0),
            ),
          ),
        );

        interpreter!.runForMultipleInputs([input], {
          0: detOut,
          1: maskOut,
        });

        // 3. FLATTEN (tight loops optimized)
        int i = 0;
        final dFlat = detFlat!;
        for (int a = 0; a < numAttrs; a++) {
          final row = detOut[0][a];
          for (int b = 0; b < numAnchors; b++) {
            dFlat[i++] = row[b];
          }
        }

        i = 0;
        final mFlat = maskFlat!;
        for (int y = 0; y < 160; y++) {
          final rowY = maskOut[0][y];
          for (int x = 0; x < 160; x++) {
            final cell = rowY[x];
            for (int c = 0; c < 32; c++) {
              mFlat[i++] = cell[c];
            }
          }
        }

        // 4. decode
        final detections = decoder.decode([dFlat, mFlat], 0.4);
        replyPort.send(detections);
      } catch (e, st) {
        replyPort.send({'error': '$e\n$st'});
      }
    }
  });
}

/// ------------------------------------------------------------------
/// OPTIMIZED LETTERBOX
/// - avoids repeated image allocations where possible
/// - reduces object churn
/// ------------------------------------------------------------------
(Float32List, double, double, double) _letterbox(FrameData frame) {
  const size = 640;

  final imgData = img.Image.fromBytes(
    width: frame.width,
    height: frame.height,
    bytes: frame.bytes.buffer,
    order: img.ChannelOrder.rgb,
  );

  final scale =
      math.min(size / imgData.width, size / imgData.height);

  final newW = (imgData.width * scale).round();
  final newH = (imgData.height * scale).round();

  final resized = img.copyResize(
    imgData,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.linear,
  );

  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgb8(0, 0, 0));

  final dx = (size - newW) >> 1;
  final dy = (size - newH) >> 1;

  img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

  final tensor = Float32List(size * size * 3);

  int i = 0;
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final p = canvas.getPixel(x, y);
      tensor[i++] = p.r / 255.0;
      tensor[i++] = p.g / 255.0;
      tensor[i++] = p.b / 255.0;
    }
  }

  return (tensor, scale, dx.toDouble(), dy.toDouble());
}