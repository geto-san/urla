import '../../database/app_database.dart';
import '../../domain/repositories/geo_repository.dart';
import '../../domain/models/geo_model.dart';
import 'package:urla/core/utils/math_utils.dart';
import 'package:drift/drift.dart';

class GeoRepositoryImpl implements GeoRepository {
  final AppDatabase _db;

  GeoRepositoryImpl(this._db);

  static const double _cellSize = 0.0002;

  @override
  ({int x, int y}) toGridCoords(double lat, double lng) {
    return (
      x: (lat / _cellSize).floor(),
      y: (lng / _cellSize).floor(),
    );
  }

  @override
  Future<void> updateCell(GeoCellModel newCell) async {
    final existing = await (_db.select(_db.geoCells)
          ..where((t) => t.x.equals(newCell.x) & t.y.equals(newCell.y)))
        .getSingleOrNull();

    if (existing == null) {
      await _db.into(_db.geoCells).insert(
        GeoCellsCompanion.insert(
          x: newCell.x,
          y: newCell.y,
          riskScore: Value(newCell.riskScore),
          stability: Value(newCell.stability),
          lastUpdated: DateTime.now(),
          sampleCount: const Value(1),
        ),
      );
      return;
    }

    final updatedRisk = runningAverage(
      existing.riskScore,
      newCell.riskScore,
      existing.sampleCount,
    );

    final updatedStability = runningAverage(
      existing.stability,
      newCell.stability,
      existing.sampleCount,
    );

    await (_db.update(_db.geoCells)
      ..where((t) => t.x.equals(newCell.x) & t.y.equals(newCell.y)))
        .write(
          GeoCellsCompanion(
            riskScore: Value(updatedRisk),
            stability: Value(updatedStability),
            sampleCount: Value(existing.sampleCount + 1),
            lastUpdated: Value(DateTime.now()),
          ),
        );
  }

  @override
  Future<GeoCellModel?> getCell(int x, int y) async {
    final result = await (_db.select(_db.geoCells)
      ..where((t) => t.x.equals(x) & t.y.equals(y)))
        .getSingleOrNull();

    if (result == null) return null;

    return GeoCellModel(
      x: result.x,
      y: result.y,
      riskScore: result.riskScore,
      stability: result.stability,
      sampleCount: result.sampleCount,
    );
  }
}