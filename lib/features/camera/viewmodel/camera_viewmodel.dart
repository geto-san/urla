import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/services/frame_processor.dart';
import '../../../core/services/output_coordinator.dart';
import '../../../core/services/tflite_service.dart';
import '../../../core/sources/camera_frame_source.dart';
import '../../../data/domain/models/frame_data.dart';
import '../../../data/runtime/models/frame_processing_result.dart';
import '../../../data/runtime/models/geo_data.dart';

// ---------------------------------------------------------------------------
// CameraViewModel
//
// Lifecycle:
//   1. Constructor — wires streams, no hardware touched.
//   2. start()     — opens camera hardware (first call only), starts stream.
//   3. stop()      — pauses stream, releases hardware lock.
//   4. dispose()   — full teardown.
//
// The camera is NEVER touched until start() is called.
// ---------------------------------------------------------------------------
class CameraViewModel {
  final CameraFrameSource  _source;
  final TFLiteService      _tflite;
  final FrameProcessor     _processor;
  final OutputCoordinator  _outputCoordinator;

  bool _initialized = false;
  bool _running     = false;

  // Back-pressure flag: only one inference in flight at a time.
  // TFLiteService also enforces this internally, but we guard here so we
  // never queue up awaiting predict() calls that pile on the isolate.
  bool _inferring = false;

  StreamSubscription<FrameData>?             _frameSubscription;
  StreamSubscription<FrameProcessingResult>? _resultSubscription;
  StreamSubscription<GeoData>?               _geoSubscription;

  // ── Public state ──────────────────────────────────────────────────────────

  /// Latest frame-processing result for the overlay painter.
  final ValueNotifier<FrameProcessingResult?> overlayData =
      ValueNotifier<FrameProcessingResult?>(null);

  /// Exposes the [CameraController] for the [CameraPreview] widget.
  /// Null until [start] completes for the first time.
  ValueNotifier<CameraController?> get controllerNotifier =>
      _source.controllerNotifier;

  final ValueNotifier<bool>     showMap    = ValueNotifier(false);
  final ValueNotifier<GeoData?> currentGeo = ValueNotifier(null);

  // ── Constructor ───────────────────────────────────────────────────────────

  CameraViewModel({
    required CameraFrameSource source,
    required TFLiteService     tflite,
    required FrameProcessor    processor,
    required OutputCoordinator outputCoordinator,
    required Stream<GeoData>   geoStream,
  })  : _source             = source,
        _tflite             = tflite,
        _processor          = processor,
        _outputCoordinator  = outputCoordinator {
    _geoSubscription = geoStream.listen((geo) => currentGeo.value = geo);
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_running) return;

    if (!_initialized) {
      // Open camera hardware exactly once.
      await _source.initialize();
      _initialized = true;

      // Subscribe to processor results once — persists across stop/start cycles.
      _resultSubscription = _processor.resultStream.listen((result) {
        overlayData.value = result;
        // Fire-and-forget: TTS + haptic never block the overlay update.
        _outputCoordinator.process(result).catchError((Object e) {
          debugPrint('OutputCoordinator error: $e');
        });
      });
    }

    await _source.start();
    _listenToFrames();
    _running = true;
  }

  Future<void> stop() async {
    if (!_running) return;
    await _frameSubscription?.cancel();
    _frameSubscription = null;
    await _source.stop();
    _running    = false;
    _inferring  = false;
  }

  Future<void> dispose() async {
    await stop();
    await _resultSubscription?.cancel();
    await _geoSubscription?.cancel();
    await _source.dispose();
    overlayData.dispose();
    showMap.dispose();
    currentGeo.dispose();
  }

  void toggleMap() => showMap.value = !showMap.value;

  // ── Frame pipeline ────────────────────────────────────────────────────────

  void _listenToFrames() {
    _frameSubscription = _source.frameStream.listen((frame) async {
      // Drop frame if inference is still running — real-time stability.
      if (_inferring) return;
      _inferring = true;

      try {
        final result = await _tflite.predict(frame);

        // result.dropped == true means TFLiteService was busy on its end too.
        // Either way, skip submitting — nothing to decode.
        if (result.dropped) return;

        _processor.submitDetections(
          result.detections,
          frame.width,
          frame.height,
        );
      } catch (e, st) {
        debugPrint('Inference error: $e\n$st');
      } finally {
        _inferring = false;
      }
    });
  }
}