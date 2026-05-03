import '../../runtime/models/lane_model.dart';

abstract class LaneRepository {

  Future<void> saveLane(
    LaneModel lane,
    {String? sessionId}
  );
}
