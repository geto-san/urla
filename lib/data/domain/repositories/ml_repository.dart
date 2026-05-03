// ml_repository.dart
import '../../runtime/models/preprocess_task.dart'; // RawPreprocessTask
import '../../runtime/models/detection_model.dart';

abstract class MLRepository {
  Future<List<DetectionModel>> runInference(RawPreprocessTask task);
}