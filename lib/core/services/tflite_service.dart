import 'dart:async';
import 'dart:isolate';

import 'package:flutter/services.dart' show rootBundle;

import '../../data/domain/models/frame_data.dart';
import '../../data/runtime/models/detection_model.dart';
import '../ml/inference_isolate.dart';

/// Manages the lifecycle of the inference isolate and exposes a
/// simple [predict] API.
///
/// [loadModel] is idempotent — calling it a second time while loading or
/// after loading is a no-op. This makes it safe to call from button handlers
/// that fire more than once before the first await resolves.
class TFLiteService {
  Isolate?   _isolate;
  SendPort?  _toIsolate;

  // Created fresh in loadModel, closed in dispose.
  // ReceivePort is single-subscription — listen() must be called exactly once.
  ReceivePort?                 _fromIsolate;
  StreamSubscription<dynamic>? _sub;

  // Pending reply map: request-id → Completer
  int _nextId = 0;
  final _pending = <int, Completer<List<DetectionModel>>>{};

  // Lazily created so isReady works even before loadModel is called.
  Completer<bool>? _readyCompleter;

  /// Resolves true when the model is hot. Safe to await from multiple callers.
  Future<bool> get isReady => (_readyCompleter ??= Completer<bool>()).future;

  bool _modelLoaded   = false;
  bool _loading       = false;   // guards against concurrent loadModel calls
  bool _inferenceBusy = false;

  // Exposed for diagnostics only.
  int detOutputSize  = 0;
  int maskOutputSize = 0;

  // Held only during the isolate handshake; null afterwards.
  Completer<SendPort>? _pendingSendPort;

  // ─────────────────────────────────────────────────────────────
  // INIT
  // ─────────────────────────────────────────────────────────────

  /// Spawns the isolate and loads the TFLite model.
  /// Idempotent: safe to call multiple times or concurrently.
  Future<void> loadModel({
    String assetPath = 'assets/models/best_float16.tflite',
  }) async {
    if (_modelLoaded || _loading) return;
    _loading = true;

    _readyCompleter ??= Completer<bool>();

    // Fresh port for this service lifetime — listen() called exactly once.
    _fromIsolate = ReceivePort();
    _sub = _fromIsolate!.cast<dynamic>().listen(_onIsolateMessage);

    try {
      // 1. Spawn isolate. It sends its SendPort as its very first message,
      //    routed via _onIsolateMessage → _pendingSendPort.
      final handshake = Completer<SendPort>();
      _pendingSendPort = handshake;

      _isolate = await Isolate.spawn(
        inferenceIsolateEntry,
        _fromIsolate!.sendPort,
        debugName: 'yolo_inference_isolate',
      );

      _toIsolate = await handshake.future
          .timeout(const Duration(seconds: 10));

      // 2. Load model bytes — must run on main isolate (rootBundle restriction).
      final bytes =
          (await rootBundle.load(assetPath)).buffer.asUint8List();

      // 3. Send init command; ack arrives through _onIsolateMessage.
      final id     = _nextId++;
      final comp   = Completer<List<DetectionModel>>();
      _pending[id] = comp;
      _toIsolate!.send([0, bytes, id]);

      // Wait for the isolate to confirm the model is allocated.
      await comp.future.timeout(const Duration(seconds: 30));
      // _modelLoaded / _loading flipped inside _onIsolateMessage on success.
    } catch (e) {
      _loading = false;
      if (!_readyCompleter!.isCompleted) _readyCompleter!.complete(false);
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // INFERENCE
  // ─────────────────────────────────────────────────────────────

  Future<({List<DetectionModel> detections, bool dropped})> predict(
    FrameData frame,
  ) async {
    if (!_modelLoaded || _toIsolate == null) {
      throw StateError(
          'TFLiteService: model not loaded — await loadModel() first');
    }

    if (_inferenceBusy) {
      return (detections: const <DetectionModel>[], dropped: true);
    }
    _inferenceBusy = true;

    final id   = _nextId++;
    final comp = Completer<List<DetectionModel>>();
    _pending[id] = comp;

    print('[TFLite] Sending frame: w=${frame.width}, h=${frame.height}, bytes.length=${frame.bytes.length}');
    _toIsolate!.send([1, frame, id]);
    print('[TFLite] Sent inference request with id=$id');

    print('[TFLite] predict() called, id=$id');

    try {
      print('[TFLite] Waiting for reply...');
      final result =
          await comp.future.timeout(const Duration(milliseconds: 10000));
      print('[TFLite] Got result with ${result.length} detections');
      return (detections: result, dropped: false);
    } on TimeoutException {
      _pending.remove(id);
      print('[TFLite] Inference timed out for id=$id');
      return (detections: const <DetectionModel>[], dropped: true);
      
    } catch (e) {
      print('[TFLite] Inference error for id=$id: $e');
      _pending.remove(id);
      rethrow;
    } finally {
      _inferenceBusy = false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // REPLY DISPATCH
  // ─────────────────────────────────────────────────────────────

  void _onIsolateMessage(dynamic msg) {
    // Handshake: isolate's first message is its own SendPort.
    if (msg is SendPort) {
      _pendingSendPort?.complete(msg);
      _pendingSendPort = null;
      return;
    }

    if (msg is! List || msg.length < 2) return;

    final id      = msg[0] as int;
    final payload = msg[1];
    final comp    = _pending.remove(id);
    if (comp == null) return;

    if (payload is Map && payload['error'] != null) {
      comp.completeError(Exception(payload['error']));
      return;
    }

    // Init ack: {detSize, maskSize}
    if (payload is Map && payload.containsKey('detSize')) {
      detOutputSize  = payload['detSize']  as int;
      maskOutputSize = payload['maskSize'] as int;
      _modelLoaded   = true;
      _loading       = false;
      if (!_readyCompleter!.isCompleted) _readyCompleter!.complete(true);
      comp.complete(const []);
      return;
    }

    // Inference reply
    if (payload is List<DetectionModel>) {
      comp.complete(payload);
      return;
    }

    comp.completeError(
        Exception('TFLiteService: unexpected isolate reply: $payload'));
  }

  // ─────────────────────────────────────────────────────────────
  // CLEANUP
  // ─────────────────────────────────────────────────────────────

  void dispose() {
    _sub?.cancel();
    _fromIsolate?.close();
    _fromIsolate = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate      = null;
    _toIsolate    = null;
    _modelLoaded  = false;
    _loading      = false;

    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(StateError('TFLiteService disposed'));
    }
    _pending.clear();

    _pendingSendPort?.completeError(StateError('TFLiteService disposed'));
    _pendingSendPort = null;
  }
}