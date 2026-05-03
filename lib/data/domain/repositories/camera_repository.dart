// camera_repository.dart
// new file (was FrameModel)

import 'package:urla/data/domain/models/raw_frame.dart';

abstract class CameraRepository {
  Stream<RawFrameData> get frameStream;
  Future<void> initialize();
  void dispose();
}