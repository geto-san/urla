import 'dart:async';
// import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:urla/data/domain/models/raw_frame.dart';

class CameraService {
  CameraController? _controller;
  final StreamController<RawFrameData> _frameStream =
      StreamController<RawFrameData>.broadcast();

  Stream<RawFrameData> get frameStream => _frameStream.stream;
  CameraController? get controller => _controller;

  Future<void> initialize() async {
    final cameras = await availableCameras();

    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await _controller!.initialize();
    _controller!.startImageStream(_onImageAvailable);
  }

  void _onImageAvailable(CameraImage image) {
    try {
      // 1. Copy raw plane data so it can be sent across isolates safely.
      final List<Uint8List> planeCopies = image.planes.map((plane) {
        // Uint8List.fromList copies the underlying bytes.
        return Uint8List.fromList(plane.bytes);
      }).toList();

      final raw = RawFrameData(
        planes: planeCopies,
        width: image.width,
        height: image.height,
        format: image.format.raw,           // e.g., 35 for yuv420
        bytesPerRow: image.planes.map((p) => p.bytesPerRow).toList(),
        bytesPerPixel: image.planes.map((p) => p.bytesPerPixel).toList(),
      );

      _frameStream.add(raw);
    } catch (e, stack) {
      // Log the error but do not let the stream die.
      debugPrint('Camera image callback error: $e\n$stack');
    }
  }

  Future<void> dispose() async {
    await _controller?.dispose();
    await _frameStream.close();
  }
}