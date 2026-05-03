import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:urla/core/services/output_coordinator.dart';
import 'package:urla/data/domain/models/raw_frame.dart';
import 'package:urla/data/domain/repositories/ml_repository.dart';
import '../../../core/services/camera_services.dart';
import '../../../core/services/frame_processor.dart';
import '../../../data/runtime/models/frame_processing_result.dart';
import '../../../data/runtime/models/preprocess_task.dart';

class CameraViewModel {
  final CameraService _cameraService;
  final FrameProcessor _processor;
  final MLRepository _mlRepo; // <-- new dependency
  final OutputCoordinator _outputCoordinator;
  bool _inferring = false;

  StreamSubscription<FrameProcessingResult>? _resultSubscription;
  final ValueNotifier<FrameProcessingResult?> overlayData =
      ValueNotifier<FrameProcessingResult?>(null);
  final ValueNotifier<CameraController?> controllerNotifier = ValueNotifier(
    null,
  );

  CameraViewModel(
    this._cameraService,
    this._processor,
    this._mlRepo, // injected
    this._outputCoordinator,
  );

  CameraController? get cameraController => _cameraService.controller;

  Future<void> initialize() async {
    await _cameraService.initialize();
    controllerNotifier.value = _cameraService.controller;

    // Listen for raw camera frames, convert, run ML, then send to processor
    _cameraService.frameStream.listen((RawFrameData raw) async {
      if (_inferring) return; // <-- drop frame if already processing
      _inferring = true;

      try {
        // Build the preprocessing task
        final task = RawPreprocessTask(
          planes: raw.planes,
          width: raw.width,
          height: raw.height,
          bytesPerRow: raw.bytesPerRow,
          bytesPerPixel: raw.bytesPerPixel,
        );

        // Run inference (preprocessing + model) in background isolate
        final detections = await _mlRepo.runInference(task);

        // Now feed the detections (and maybe raw frame metadata) to the processor
        _processor.submitDetections(detections, raw.width, raw.height);
      } catch (e, st) {
        debugPrint('Inference error: $e\n$st');
      } finally {
        _inferring = false;
      }
    });

    // Listen for processed results to update overlay
    _resultSubscription = _processor.resultStream.listen((result) {
      overlayData.value = result;
      unawaited(_outputCoordinator.process(result));   // fire-and-forget TTS + haptic
    });
  }

  Future<void> dispose() async {
    controllerNotifier.dispose();
    _resultSubscription?.cancel();
    _processor.dispose();
    overlayData.dispose();
    await _cameraService.dispose();
  }
}
