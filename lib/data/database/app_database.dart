import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/frame_observations.dart';
import 'tables/detection_events.dart';
import 'tables/lane_snapshots.dart';
import 'tables/driving_events.dart';
import 'tables/geo_cells.dart';
import 'tables/road_segments.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    FrameObservations,
    DetectionEvents,
    LaneSnapshots,
    DrivingEvents,
    GeoCells,
    RoadSegments,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {

    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'urla_database.sqlite'));
    return NativeDatabase(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode=WAL;');
        db.execute('PRAGMA synchronous=NORMAL;');
      },
    );
  });
}
