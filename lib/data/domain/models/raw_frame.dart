import 'dart:typed_data';

/// Raw, unprocessed frame data straight from the camera.
/// Intended to be sent to a preprocessing isolate for YUV→RGB conversion.
class RawFrameData {
  final List<Uint8List> planes;
  final int width;
  final int height;
  final int format;          // ImageFormatGroup index (e.g., yuv420)
  final List<int> bytesPerRow;
  final List<int?> bytesPerPixel;

  const RawFrameData({
    required this.planes,
    required this.width,
    required this.height,
    required this.format,
    required this.bytesPerRow,
    required this.bytesPerPixel,
  });
}
