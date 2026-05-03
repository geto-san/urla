import 'dart:typed_data';

/// Raw camera frame passed into ML pipeline.
/// Represents a single time-sliced vision input.
class FrameModel {

  final Uint8List bytes;
  final int width;
  final int height;
  final DateTime timestamp;

  const FrameModel({
    required this.bytes,
    required this.width,
    required this.height,
    required this.timestamp,
  });

  int get pixelCount => width * height;
}