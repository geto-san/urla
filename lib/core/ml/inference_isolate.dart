import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../data/domain/models/frame_data.dart';
import 'yolo_decoder.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ISOLATE ENTRY
// ─────────────────────────────────────────────────────────────────────────────

/// Top-level entry for the inference isolate.
///
/// Message protocol (List<dynamic>):
///   [0, modelBytes, replyPort]  → init model
///   [1, FrameData,  replyPort]  → run inference
void inferenceIsolateEntry(SendPort mainSendPort) {
  final port = ReceivePort();
  mainSendPort.send(port.sendPort);

  Interpreter? interpreter;
  final decoder = YoloSegDecoder();

  // Output tensor shapes (set after init)
  int numAttrs = 0; // 39  (det first dim)
  int numAnchors = 0; // 8400
  // Note: proto is always [1, 160, 160, 32] → 160*160*32 = 819200

  // ── Preallocated flat output buffers ──────────────────────────────────────
  // We reuse the same Float32List every frame to avoid GC pressure.
  //
  // det layout  : [attr, anchor]  →  detFlat[a*numAnchors + anchor]
  // proto layout: [y, x, coeff]   →  protoFlat[y*160*32 + x*32 + c]
  //
  // After transposing det to [anchor, attr] for decoder:
  //   detTransposed[anchor*stride + attr]
  Float32List? _detRaw; // numAttrs × numAnchors
  Float32List? _detTransposed; // numAnchors × numAttrs  (decoder input)
  Float32List? _protoFlat; // 160 × 160 × 32  (decoder input, pixel-major)

  // Store the main port so we can reply without needing a SendPort in every message
  final SendPort replyTo = mainSendPort;

  port.listen((message) {
    print('[Isolate] Raw message received: $message'); 
    if (message is! List || message.isEmpty) return;
    final tag = message[0] as int;
    final id  = message[2] as int; 

    // =========================================================================
    // INIT
    // =========================================================================
    print('[Isolate] Received message with tag $tag and id $id');
    if (tag == 0) {
      print('[Isolate] Received INIT command');
      final modelBytes = message[1] as Uint8List;
      try {
        print('[Isolate] Loading interpreter...');
        interpreter = _loadInterpreter(modelBytes);
        interpreter!.allocateTensors();

        final detShape = interpreter!.getOutputTensor(0).shape; // [1, 39, 8400]
        final maskShape = interpreter!
            .getOutputTensor(1)
            .shape; // [1, 160, 160, 32]

        // Validate expected layout
        if (detShape.length != 3 || maskShape.length != 4) {
          throw StateError(
            'Unexpected tensor shapes: det=$detShape mask=$maskShape',
          );
        }

        numAttrs = detShape[1]; // 39
        numAnchors = detShape[2]; // 8400

        // Allocate once
        _detRaw = Float32List(numAttrs * numAnchors);
        _detTransposed = Float32List(numAnchors * numAttrs);
        _protoFlat = Float32List(160 * 160 * 32);

        print('[Isolate] Interpreter loaded, sending reply');
        replyTo.send([id, {
          'detSize': numAnchors * numAttrs,
          'maskSize': 160 * 160 * 32,
        }]);
      } catch (e, st) {
        print('[Isolate] ERROR: $e');
        replyTo.send([id, {'error': '$e\n$st'}]);
      }
    }
    // =========================================================================
    // INFERENCE
    // =========================================================================
    else if (tag == 1) {
      print('[Isolate] Received INFERENCE command with id $id');
      final frame = message[1] as FrameData;
      try {
        print('[Isolate] Processing inference request with id $id');
        if (interpreter == null ||
            _detRaw == null ||
            _detTransposed == null ||
            _protoFlat == null) {
          print('[Isolate] ERROR: Model not initialised');
          replyTo.send([id, {'error': 'Model not initialised'}]);
          return;
        }

        // 1. Letterbox preprocess → [1, 640, 640, 3] float32 tensor
        final (tensor, scale, dx, dy) = _letterbox(frame);
        decoder.setPreprocessParams(scale, dx, dy);

        // 2. Run inference
        //    Use typed output maps so TFLite writes directly into our
        //    Float32List buffers — zero copy from C++ side.
        //    We reshape the buffers to match TFLite's expected nested shape.
        //    TFLite fills the underlying bytes regardless of Dart List wrapper.
        
        final input = tensor.reshape([1, 640, 640, 3]);

        final outputs = <Object>[
          _detRaw!.reshape([1, numAttrs, numAnchors]),
          _protoFlat!.reshape([1, 160, 160, 32]),
        ];

        interpreter!.run(input, outputs);

        // DEBUG — verify model output
        double maxVal = -1e9;
        double minVal = 1e9;

        for (final v in _detRaw!) {
          if (v > maxVal) maxVal = v;
          if (v < minVal) minVal = v;
        }

        print('[DEBUG] detRaw range: $minVal -> $maxVal');

        // 3. Transpose det from [numAttrs, numAnchors] → [numAnchors, numAttrs]
        //    i.e. detRaw[a*numAnchors + n] → detT[n*numAttrs + a]
        //    This mirrors Python: pred = det_out[0].T
        final det = _detRaw!;
        final detT = _detTransposed!;
        for (int a = 0; a < numAttrs; a++) {
          final rowBase = a * numAnchors;
          for (int n = 0; n < numAnchors; n++) {
            detT[n * numAttrs + a] = det[rowBase + n];
          }
        }

        // DEBUG — check highest class score
        double bestScore = 0;

        for (int i = 0; i < numAnchors; i++) {
          final row = i * numAttrs;

          final s = math.max(
            detT[row + 4],
            math.max(detT[row + 5], detT[row + 6]),
          );

          if (s > bestScore) bestScore = s;
        }

        print('[DEBUG] best class score: $bestScore');

        // 4. Rearrange proto from [160, 160, 32] (channel-last)
        //    to pixel-major [pixel, 32] for decoder dot-product.
        //    Since TFLite writes channel-last and our decoder expects
        //    proto[pixel * 32 + coeff], the layout is already correct — no copy needed.
        //    (proto[y*160*32 + x*32 + c] == protoFlat[pixel*32 + c] where pixel=y*160+x)

        // 5. Decode
        final detections = decoder.decode(_detTransposed!, _protoFlat!, 0.1);
        print('[Isolate] Inference completed with ${detections.length} detections');
        replyTo.send([id, detections]);
      } catch (e, st) {
        print('[Isolate] ERROR during inference: $e');
        replyTo.send([id, {'error': '$e\n$st'}]);
      }
    }
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// INTERPRETER INIT  (GPU → CPU fallback)
// ─────────────────────────────────────────────────────────────────────────────

Interpreter _loadInterpreter(Uint8List modelBytes) {
  // Try GPU delegate first
  // try {
  //   final delegate = GpuDelegateV2(
  //     options: GpuDelegateOptionsV2(isPrecisionLossAllowed: true),
  //   );
  //   final interp = Interpreter.fromBuffer(
  //     modelBytes,
  //     options: InterpreterOptions()..addDelegate(delegate),
  //   );
  //   // Quick shape check: if GPU failed silently the output tensors are often
  //   // unallocated or empty — validate immediately.
  //   interp.allocateTensors();
  //   final shape = interp.getOutputTensor(0).shape;
  //   if (shape.isEmpty) throw StateError('GPU delegate produced empty tensors');
  //   return interp;
  // } catch (_) {
  //   // GPU unavailable or failed — fall back to multi-threaded CPU
  // }

  return Interpreter.fromBuffer(
    modelBytes,
    options: InterpreterOptions()..threads = 4,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// LETTERBOX PREPROCESSING
// ─────────────────────────────────────────────────────────────────────────────
//
// Mirrors the Python reference exactly:
//   img_resized = cv2.resize(img_rgb, (IMG_SIZE, IMG_SIZE))   ← stretch, NOT letterbox
//
// Wait — the Python script actually does a plain resize (no letterbox).
// The Dart decoder DOES apply letterbox unboxing though, so we must be consistent.
//
// DECISION: Use letterbox here (correct for Ultralytics models trained with
// letterbox augmentation) and unbox in the decoder. This matches the Dart
// decoder's setPreprocessParams call. If your model was exported/trained
// without letterbox, swap to plain resize and set scale=min(640/W,640/H), dx=dy=0.

(Float32List, double, double, double) _letterbox(FrameData frame) {
  const size = 640;

  final src = img.Image.fromBytes(
    width: frame.width,
    height: frame.height,
    bytes: frame.bytes.buffer,
    order: img.ChannelOrder.rgb,
  );

  final scale = math.min(size / src.width, size / src.height);
  final newW = (src.width * scale).round();
  final newH = (src.height * scale).round();

  final resized = img.copyResize(
    src,
    width: newW,
    height: newH,
    interpolation: img.Interpolation.linear,
  );

  final canvas = img.Image(width: size, height: size);
  img.fill(canvas, color: img.ColorRgb8(114, 114, 114)); // YOLOv8 grey pad

  final dx = (size - newW) >> 1;
  final dy = (size - newH) >> 1;

  img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

  // Build Float32 tensor directly — avoids getPixel object allocations
  final tensor = Float32List(size * size * 3);
  final bytes = canvas.toUint8List(); // RGB interleaved
  for (int i = 0, j = 0; i < bytes.length; i++) {
    tensor[j++] = bytes[i] / 255.0;
  }

  return (tensor, scale, dx.toDouble(), dy.toDouble());
}
