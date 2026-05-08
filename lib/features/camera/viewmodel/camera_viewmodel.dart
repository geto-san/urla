import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:urla/core/services/output_coordinator.dart';
import 'package:urla/data/domain/models/frame_data.dart';
import 'package:urla/data/runtime/models/frame_processing_result.dart';
import 'package:urla/data/runtime/models/geo_data.dart';
import '../../../core/services/frame_processor.dart';
import '../../../core/services/tflite_service.dart';
import '../../../core/sources/camera_frame_source.dart';

// ---------------------------------------------------------------------------
// CameraViewModel
//
// Lifecycle:
//
//   1. Constructor — wires streams, no hardware.
//   2. initialize() — called by DashboardScreen.initState() via start().
//        Opens camera hardware, sets up frame listener, starts inference.
//   3. stop() — called when leaving Dashboard or entering image test.
//        Stops image stream, releases hardware.
//   4. start() — called when returning to Dashboard.
//        Re-initializes if needed, restarts stream.
//   5. dispose() — full teardown.
//
// The camera hardware is NEVER touched until start() is called.
// ---------------------------------------------------------------------------
class CameraViewModel {
  final CameraFrameSource _source;
  final TFLiteService     _tflite;
  final FrameProcessor    _processor;
  final OutputCoordinator _outputCoordinator;

  bool _inferring    = false;
  bool _initialized  = false;
  bool _running      = false;

  StreamSubscription<FrameData>?              _frameSubscription;
  StreamSubscription<FrameProcessingResult>?  _resultSubscription;
  StreamSubscription<GeoData>?                _geoSubscription;

  final ValueNotifier<FrameProcessingResult?> overlayData =
      ValueNotifier<FrameProcessingResult?>(null);

  // Exposes the CameraController for CameraPreview widget.
  // Null until initialize() completes.
  ValueNotifier<CameraController?> get controllerNotifier =>
      _source.controllerNotifier;

  final ValueNotifier<bool>     showMap    = ValueNotifier(false);
  final ValueNotifier<GeoData?> currentGeo = ValueNotifier(null);

  CameraViewModel({
    required CameraFrameSource source,
    required TFLiteService     tflite,
    required FrameProcessor    processor,
    required OutputCoordinator outputCoordinator,
    required Stream<GeoData>   geoStream,
  })  : _source            = source,
        _tflite            = tflite,
        _processor         = processor,
        _outputCoordinator = outputCoordinator {
    _geoSubscription = geoStream.listen((geo) => currentGeo.value = geo);
  }

  // ── Called by DashboardScreen.initState() ─────────────────────────────────
  Future<void> start() async {
    if (_running) return;

    if (!_initialized) {
      // Phase 2: open camera hardware (first time only).
      await _source.initialize();
      _initialized = true;

      // Subscribe to pipeline results once.
      _resultSubscription = _processor.resultStream.listen((result) {
        overlayData.value = result;
        // Fire-and-forget TTS + haptic — never blocks overlay update.
        _outputCoordinator.process(result).catchError((e) {
          debugPrint('OutputCoordinator error: $e');
        });
      });
    }

    // Start camera stream + frame listener.
    await _source.start();
    _listenToFrames();
    _running = true;
  }

  // ── Called when leaving Dashboard or entering image test ──────────────────
  Future<void> stop() async {
    if (!_running) return;
    await _source.stop();
    await _frameSubscription?.cancel();
    _frameSubscription = null;
    _running   = false;
    _inferring = false;
  }

  // ── Full disposal ─────────────────────────────────────────────────────────
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

  // ── Internal frame pipeline ───────────────────────────────────────────────
  void _listenToFrames() {
    _frameSubscription = _source.frameStream.listen((frame) async {
      // Drop frame if inference is still running (back-pressure).
      if (_inferring) return;
      _inferring = true;

      try {
        final detections = await _tflite.predict(frame);
        _processor.submitDetections(detections, frame.width, frame.height);
      } catch (e, st) {
        debugPrint('Inference error: $e\n$st');
      } finally {
        _inferring = false;
      }
    });
  }
}
