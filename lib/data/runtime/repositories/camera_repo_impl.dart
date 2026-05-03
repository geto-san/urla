import 'package:urla/data/domain/models/raw_frame.dart';

import '../../../core/services/camera_services.dart';
import '../../domain/repositories/camera_repository.dart';
  // new model holding planes

class CameraRepositoryImpl implements CameraRepository {
  final CameraService _cameraService;

  CameraRepositoryImpl(this._cameraService);

  @override
  Stream<RawFrameData> get frameStream => _cameraService.frameStream;

  @override
  Future<void> initialize() => _cameraService.initialize();

  @override
  void dispose() => _cameraService.dispose();
}