import 'package:drift/drift.dart';
/// GEO-SPATIAL MEMORY (GRID SYSTEM)
///
/// Grid-based spatial intelligence map.
///
/// The environment is divided into square cells.
/// Each cell accumulates risk information derived
/// from driving observations.
///
/// This structure enables fast geospatial lookups.
@TableIndex(name: 'geo_coord_idx', columns: {#x, #y})
@TableIndex(name: 'geo_updated_idx', columns: {#lastUpdated})
class GeoCells extends Table {

  IntColumn get x => integer()();
  IntColumn get y => integer()();

  RealColumn get riskScore => real()();
  RealColumn get stability => real()();

  IntColumn get sampleCount => integer()();

  DateTimeColumn get lastUpdated =>
    dateTime().clientDefault(() => DateTime.now())();

  @override
  Set<Column> get primaryKey => {x, y};
}