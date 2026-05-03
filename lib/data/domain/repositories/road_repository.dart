import '../models/road_model.dart';
import '../../runtime/models/lane_model.dart';

abstract class RoadRepository {
  Future<void> updateRoadFromLane(
    double lat,
    double lng,
    LaneModel lane,
  );

  Future<RoadModel?> getRoadStats(String roadId);

  Future<int> getHistoricalRisk(String roadId);
}
