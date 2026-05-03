import 'dart:typed_data';

/// Task passed to the preprocessing isolate.
/// Contains raw YUV planes and metadata from the camera.
class RawPreprocessTask {
  final List<Uint8List> planes;
  final int width;
  final int height;

  /// bytesPerRow for each plane
  final List<int> bytesPerRow;

  /// bytesPerPixel for each plane (nullable – camera API uses null for 1)
  final List<int?> bytesPerPixel;

  const RawPreprocessTask({
    required this.planes,
    required this.width,
    required this.height,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });
}