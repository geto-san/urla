import '../../domain/enums.dart';
import '../../domain/repositories/road_repository.dart';
import '../../database/app_database.dart';
import '../models/lane_model.dart';
import '../../domain/models/road_model.dart';
import 'package:urla/core/utils/math_utils.dart';
import 'package:drift/drift.dart';

class RoadRepositoryImpl implements RoadRepository {
  final AppDatabase _db;

  RoadRepositoryImpl(this._db);


  /// Classify road type based on lane geometry.
  /// Thresholds are example – tune as needed.
  RoadType _classifyRoadType(LaneModel lane) {
    if (lane.laneWidth > 3.8 && lane.curvature < 0.2) return RoadType.highway;
    if (lane.laneWidth >= 2.8 && lane.curvature < 0.5) return RoadType.urban;
    return RoadType.rural;
  }

  @override
  Future<void> updateRoadFromLane(double lat, double lng, LaneModel lane) async {
    
    final id = _roadId(lat, lng);

    await _db.transaction(() async {

      final existing = await getRoadStats(id);
      final curvature = lane.curvature;
      final roadType = _classifyRoadType(lane);

      if (existing == null) {
        
        await _db.into(_db.roadSegments).insert(
          RoadSegmentsCompanion.insert(
            id: id,
            lat: lat,
            lng: lng,
            avgLaneWidth: lane.laneWidth,
            avgCurvature: curvature,
            avgDrift: lane.driftScore,
            roadType: roadType.name,
            sampleCount: const Value(1),
            lastSeen: DateTime.now(),
          ),
        );
        return;
      }

      final updatedWidth = runningAverage(existing.avgLaneWidth, lane.laneWidth, existing.sampleCount);
      final updatedCurvature = runningAverage(existing.avgCurvature, curvature, existing.sampleCount);
      final updatedDrift = runningAverage(existing.avgDrift, lane.driftScore, existing.sampleCount);
      final computedType = _classifyRoadType(lane);
      final updatedType = existing.sampleCount > 10 ? existing.roadType : computedType;

      final updated = RoadSegmentsCompanion(
        id: Value(id),
        lat: Value(lat),
        lng: Value(lng),
        avgLaneWidth: Value(updatedWidth),
        avgCurvature: Value(updatedCurvature),
        avgDrift: Value(updatedDrift),
        roadType: Value(updatedType.name),
        sampleCount: Value(existing.sampleCount + 1),
        lastSeen: Value(DateTime.now()),
      );
      await _db.into(_db.roadSegments).insertOnConflictUpdate(updated);
    });
  }

  @override
  Future<RoadModel?> getRoadStats(String id) async {
    final row = await (_db.select(_db.roadSegments)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (row == null) return null;

    return RoadModel(
      id: row.id,
      lat: row.lat,
      lng: row.lng,
      avgLaneWidth: row.avgLaneWidth,
      avgCurvature: row.avgCurvature,
      avgDrift: row.avgDrift,
      roadType: RoadType.values.firstWhere((e) => e.name == row.roadType),
      sampleCount: row.sampleCount,
    );
  }

  @override
  Future<int> getHistoricalRisk(String id) async {
    final stats = await getRoadStats(id);
    if (stats == null) return 0;

    int risk = 0;
    if (stats.avgDrift > 0.5) risk += 2;
    if (stats.avgCurvature > 0.6) risk += 1;
    if (stats.sampleCount > 50) risk += 1;
    return risk;
  }

  String _roadId(double lat, double lng) =>
      "${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}";

}