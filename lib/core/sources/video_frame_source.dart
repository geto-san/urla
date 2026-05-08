import 'dart:async';
import '../../data/domain/models/frame_data.dart';

class VideoFrameSource implements FrameSource {
  // TODO: implement using video_player plugin, extract frames, emit FrameData
  final StreamController<FrameData> _controller =
      StreamController<FrameData>.broadcast();

  @override
  Stream<FrameData> get frameStream => _controller.stream;

  @override
  Future<void> start() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}