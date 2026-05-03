import '../../domain/enums.dart';
import '../../domain/models/geometry/point.dart';

/// Final interpreted lane geometry
/// produced after AI inference.
class LaneModel {

  final List<Point> centerLine;
  final List<Point> leftBoundary;
  final List<Point> rightBoundary;

  final double laneWidth;
  final double confidence;
  final double driftScore;
  final double curvature;

  final LaneType type;

  const LaneModel({
    required this.centerLine,
    required this.leftBoundary,
    required this.rightBoundary,
    required this.laneWidth,
    required this.confidence,
    required this.driftScore,
    required this.curvature,
    required this.type,
  });

  bool get isStable => confidence > 0.6;
  bool get isDangerousDrift => driftScore > 0.7;
}