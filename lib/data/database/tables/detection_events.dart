import 'package:drift/drift.dart';

///
///ML INFRENCE LAYER (TIME-SERIES CORE)
///
@TableIndex(name: 'detection_time_idx', columns: {#timestamp})
@TableIndex(name: 'detection_frame_idx', columns: {#frameSessionId})
@TableIndex(name: 'detection_conf_idx', columns: {#confidence})
class DetectionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get timestamp => dateTime()();

  TextColumn get frameSessionId => text()();

  IntColumn get classId => integer()();
  TextColumn get className => text()();

  RealColumn get confidence => real()();

  RealColumn get xMin => real()();
  RealColumn get yMin => real()();
  RealColumn get xMax => real()();
  RealColumn get yMax => real()();

  /// serialized segmentation mask (JSON)
  TextColumn get mask => text().withLength(min: 0)();
}
