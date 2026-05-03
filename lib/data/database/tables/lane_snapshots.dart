import 'package:drift/drift.dart';


/// LANE LAYER (ENGINE OUTPUT TIME SERIES)
///
/// Stores per-frame lane detection results produced by the AI pipeline.
///
/// This table acts as a historical dataset used for:
/// • Temporal smoothing
/// • Offline analysis
/// • Model retraining
/// • Lane stability estimation
///
/// Geometry is serialized as JSON strings.
///
@TableIndex(name: 'lane_time_idx', columns: {#timestamp})
@TableIndex(name: 'lane_session_idx', columns: {#frameSessionId})
@TableIndex(name: 'lane_conf_idx', columns: {#confidence})
class LaneSnapshots extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get timestamp => dateTime()();

  TextColumn get frameSessionId => text()();

  RealColumn get confidence => real()();
  RealColumn get driftScore => real()();
  RealColumn get curvature => real()();
  RealColumn get laneWidth => real()();

  TextColumn get laneType => text()();

  TextColumn get centerLine => text()();
  TextColumn get leftBoundary => text()();
  TextColumn get rightBoundary => text()();

  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
}
