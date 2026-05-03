import 'dart:convert';
import '../../database/app_database.dart';
import '../../domain/repositories/lane_repository.dart';
import '../models/lane_model.dart';
import 'package:drift/drift.dart';

class LaneRepositoryImpl implements LaneRepository {
  final AppDatabase _db;


  LaneRepositoryImpl(this._db);

  @override
  Future<void> saveLane(LaneModel lane, {String? sessionId}) async {
    if (lane.centerLine.isEmpty) return;

    // Serialise geometry as proper JSON, not .toString()
    final centerLineJson = jsonEncode(
      lane.centerLine.map((p) => p.toJson()).toList(),
    );
    final leftBoundaryJson = jsonEncode(
      lane.leftBoundary.map((p) => p.toJson()).toList(),
    );
    final rightBoundaryJson = jsonEncode(
      lane.rightBoundary.map((p) => p.toJson()).toList(),
    );

    await _db.into(_db.laneSnapshots).insert(
      LaneSnapshotsCompanion.insert(
        frameSessionId: Value(sessionId ?? 'default'),
        timestamp: DateTime.now(),
        confidence: lane.confidence,
        driftScore: lane.driftScore,
        curvature: lane.curvature,
        laneWidth: lane.laneWidth,
        laneType: lane.type.name,
        centerLine: centerLineJson,
        leftBoundary: leftBoundaryJson,
        rightBoundary: rightBoundaryJson,
        // GPS coordinates should come from actual geolocation, not image points
        latitude: const Value(null),
        longitude: const Value(null),
      ),
    );
  }
}