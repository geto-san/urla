import 'package:drift/drift.dart';
/// ROAD MEMORY LAYER (LONG-TERM LEARNING)
/// 
/// Represents learned behaviour of a road segment.
///
/// This acts as the system's **long-term road memory**.
///
/// Each row aggregates statistics gathered over time
/// from multiple driving passes.
@TableIndex(name: 'road_location_idx', columns: {#lat, #lng})
@TableIndex(name: 'road_seen_idx', columns: {#lastSeen})
@TableIndex(name: 'road_type_idx', columns: {#roadType})
class RoadSegments extends Table {

  TextColumn get id => text()();

  RealColumn get lat => real()();
  RealColumn get lng => real()();

  RealColumn get avgLaneWidth => real()();
  RealColumn get avgCurvature => real()();
  RealColumn get avgDrift => real()();

  TextColumn get roadType => text()();

  IntColumn get sampleCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastSeen => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}