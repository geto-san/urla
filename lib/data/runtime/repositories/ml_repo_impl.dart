import '../../../core/services/tflite_service.dart';
import '../../domain/repositories/ml_repository.dart';
import '../models/detection_model.dart';
import '../models/preprocess_task.dart'; // RawPreprocessTask

class MLRepositoryImpl implements MLRepository {
  final TFLiteService _service;

  MLRepositoryImpl(this._service);

  @override
  Future<List<DetectionModel>> runInference(RawPreprocessTask task) {
    return _service.predict(task);
  }
}