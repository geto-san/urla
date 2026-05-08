import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import '../../data/domain/models/frame_data.dart';

class CameraFrameSource implements FrameSource {
  CameraController? _controller;
  final StreamController<FrameData> _frameStreamController =
      StreamController<FrameData>.broadcast();

  // Required for CameraPreview widget
  final ValueNotifier<CameraController?> controllerNotifier =
      ValueNotifier<CameraController?>(null);

  @override
  Stream<FrameData> get frameStream => _frameStreamController.stream;

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
    controllerNotifier.value = _controller;   // expose for preview
  }

  @override
  Future<void> start() async {
    _controller?.startImageStream(_onImageAvailable);
  }

  @override
  Future<void> stop() async {
    await _controller?.stopImageStream();
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller?.dispose();
    await _frameStreamController.close();
  }

  void _onImageAvailable(CameraImage image) {
    try {
      final List<Uint8List> planes =
          image.planes.map((p) => Uint8List.fromList(p.bytes)).toList();

      final rgbBytes = _yuv420ToRgb(
        planes,
        image.width,
        image.height,
        image.planes.map((p) => p.bytesPerRow).toList(),
        image.planes.map((p) => p.bytesPerPixel).toList(),
      );

      _frameStreamController.add(FrameData(
        bytes: rgbBytes,
        width: image.width,
        height: image.height,
      ));
    } catch (e, stack) {
      debugPrint('Camera frame conversion error: $e\n$stack');
    }
  }

  // ---------- YUV→RGB conversion (formerly PreprocessService) ----------
  static Uint8List _yuv420ToRgb(
    List<Uint8List> planes,
    int width,
    int height,
    List<int> bytesPerRow,
    List<int?> bytesPerPixel,
  ) {
    final Uint8List yPlane = planes[0];
    final Uint8List uPlane = planes[1];
    final Uint8List vPlane = planes.length > 2 ? planes[2] : planes[1];
    final bool interleavedUV = (bytesPerPixel[1] ?? 1) == 2;
    final int yRowStride = bytesPerRow[0];
    final int uvRowStride = bytesPerRow[1];
    final int uvPixelStride = interleavedUV ? 2 : 1;

    final Uint8List rgb = Uint8List(width * height * 3);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int yIndex = y * yRowStride + x;
        final int yVal = yPlane[yIndex];

        int uVal, vVal;
        if (interleavedUV) {
          final int uvIndex = uvRowStride * (y ~/ 2) + (x ~/ 2) * 2;
          uVal = uPlane[uvIndex] - 128;
          vVal = uPlane[uvIndex + 1] - 128;
        } else {
          final int uvIndex = uvRowStride * (y ~/ 2) + (x ~/ 2) * uvPixelStride;
          uVal = uPlane[uvIndex] - 128;
          vVal = vPlane[uvIndex] - 128;
        }

        int r = (yVal + 1.402 * vVal).round().clamp(0, 255);
        int g = (yVal - 0.344 * uVal - 0.714 * vVal).round().clamp(0, 255);
        int b = (yVal + 1.772 * uVal).round().clamp(0, 255);

        final int rgbIndex = (y * width + x) * 3;
        rgb[rgbIndex] = r;
        rgb[rgbIndex + 1] = g;
        rgb[rgbIndex + 2] = b;
      }
    }
    return rgb;
  }
}