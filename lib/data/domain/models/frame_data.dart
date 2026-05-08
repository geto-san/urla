import 'dart:async';
import 'dart:typed_data';

/// A single frame, already converted to tightly packed RGB bytes.
class FrameData {
  final Uint8List bytes;   // length = width * height * 3
  final int width;
  final int height;

  const FrameData({
    required this.bytes,
    required this.width,
    required this.height,
  });
}

/// Common interface for all sources (camera, image, video).
abstract class FrameSource {
  Stream<FrameData> get frameStream;

  /// Start producing frames (e.g. open camera, start video playback).
  Future<void> start();

  /// Stop producing frames.
  Future<void> stop();

  /// Release resources permanently.
  Future<void> dispose();
}