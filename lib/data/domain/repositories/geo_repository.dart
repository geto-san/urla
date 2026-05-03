import '../models/geo_model.dart';

abstract class GeoRepository {
  ({int x, int y}) toGridCoords(double lat, double lng);

  Future<void> updateCell(GeoCellModel cell);

  Future<GeoCellModel?> getCell(int x, int y);
}
