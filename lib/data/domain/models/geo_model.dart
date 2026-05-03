/// Grid-based spatial intelligence cell.
///
/// The world map is divided into grid cells.
/// Each cell accumulates driving statistics
/// observed in that geographic region.
class GeoCellModel {

  final int x;
  final int y;

  final double riskScore;
  final double stability;

  final int sampleCount;

  const GeoCellModel({
    required this.x,
    required this.y,
    required this.riskScore,
    required this.stability,
    required this.sampleCount,
  });
}