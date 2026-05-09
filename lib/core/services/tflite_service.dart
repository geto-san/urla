import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart' show rootBundle;

import '../../data/domain/models/frame_data.dart';
import '../../data/runtime/models/detection_model.dart';
import 'inference_isolate.dart';

enum _IsolateCommand { init, infer }

class _IsolateRequest {
  final _IsolateCommand cmd;
  final Object? payload;
  final SendPort replyPort;

  const _IsolateRequest(this.cmd, this.payload, this.replyPort);
}

class TFLiteService {
  Isolate? _isolate;
  SendPort? _sendPort;

  final ReceivePort _receivePort = ReceivePort();
  StreamSubscription? _sub;

  bool _ready = false;

  // Only allow 1 inference at a time (critical for FPS stability)
  bool _inferenceBusy = false;

  int detectionOutputSize = 0;
  int maskProtoSize = 0;

  /// -----------------------------
  /// INIT
  /// -----------------------------
  Future<void> loadModel() async {
    final portCompleter = Completer<SendPort>();

    _sub = _receivePort.listen((msg) {
      if (msg is SendPort && !portCompleter.isCompleted) {
        portCompleter.complete(msg);
      }
    });

    _isolate = await Isolate.spawn(
      inferenceIsolateEntry,
      _receivePort.sendPort,
      debugName: 'yolo_inference_isolate',
    );

    _sendPort = await portCompleter.future;

    final modelBytes =
        (await rootBundle.load('assets/models/best_float16.tflite'))
            .buffer
            .asUint8List();

    final loadReply = ReceivePort();
    _sendPort!.send([0, modelBytes, loadReply.sendPort]);

    final response = await loadReply.first;
    loadReply.close();

    if (response is Map && response['error'] != null) {
      throw Exception('Model load failed: ${response['error']}');
    }

    detectionOutputSize = response['detSize'] as int;
    maskProtoSize = response['maskSize'] as int;

    _ready = true;
  }

  /// -----------------------------
  /// INFERENCE (THROTTLED)
  /// -----------------------------
  Future<List<DetectionModel>> predict(FrameData frame) async {
    if (!_ready || _sendPort == null) {
      throw StateError('Model not ready');
    }

    // Drop frames if busy (prevents backlog → latency explosion)
    if (_inferenceBusy) {
      throw StateError('Inference busy (frame dropped for real-time stability)');
    }

    _inferenceBusy = true;

    final replyPort = ReceivePort();

    try {
      _sendPort!.send([1, frame, replyPort.sendPort]);

      final result = await replyPort.first
          .timeout(const Duration(milliseconds: 120));

      if (result is List<DetectionModel>) {
        return result;
      }

      if (result is Map && result['error'] != null) {
        throw Exception(result['error']);
      }

      throw Exception('Invalid inference response');
    } finally {
      replyPort.close();
      _inferenceBusy = false;
    }
  }

  /// -----------------------------
  /// CLEANUP
  /// -----------------------------
  void dispose() {
    _sub?.cancel();
    _receivePort.close();
    _isolate?.kill(priority: Isolate.immediate);

    _isolate = null;
    _sendPort = null;
    _ready = false;
  }
}