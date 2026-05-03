import 'package:drift/drift.dart';
/// FRAME LAYER (RAW INPUT STREAM)
/// 
/// Raw camera frames metadata (NOT image bytes stored here)
/// Keeps DB lightweight and fast.
@TableIndex(name: 'frame_timestamp_idx', columns: {#timestamp})
@TableIndex(name: 'frame_session_idx', columns: {#sessionId})
class FrameObservations extends Table {

  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get timestamp => dateTime()();

  IntColumn get width => integer()();
  IntColumn get height => integer()();

  /// links ML inference to frame
  TextColumn get sessionId => text()();

}