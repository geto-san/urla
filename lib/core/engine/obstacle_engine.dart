import '../../data/runtime/models/detection_model.dart';
import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/models/geometry/point.dart';
import '../../data/runtime/models/obstacle_model.dart';

class ObstacleEngine {
  final double imageWidth;
  final double imageHeight;

  ObstacleEngine({this.imageWidth = 640, this.imageHeight = 640});

  ObstacleState evaluate(List<DetectionModel> detections, LaneModel lane) {
    final obstacles = detections
        .where((d) => d.className == 'road_obstruction')
        .toList();

    if (obstacles.isEmpty) return ObstacleState.none();

    DetectionModel? closest;
    double highestProximity = double.negativeInfinity;

    for (final obs in obstacles) {
      final centroid = _centroid(obs.mask);
      if (!_insideLaneCorridor(centroid, lane)) continue;

      final proximity = _computeProximity(centroid); // now 0..1
      if (proximity > highestProximity) {
        highestProximity = proximity;
        closest = obs;
      }
    }

    if (closest == null) return ObstacleState.none();
    return ObstacleState(
      obstacleAhead: true,
      confidence: closest.confidence,
      proximity: highestProximity,
    );
  }

  Point _centroid(List<Point> mask) {
    if (mask.isEmpty) return const Point(0, 0);   // guard added
    double x = 0, y = 0;
    for (final p in mask) { x += p.x; y += p.y; }
    return Point(x / mask.length, y / mask.length);
  }

  /// Checks if a point lies inside the lane corridor formed by left/right boundaries.
  bool _insideLaneCorridor(Point p, LaneModel lane) {
    if (lane.leftBoundary.isEmpty || lane.rightBoundary.isEmpty) return true;

    // Simple approach: find the two closest boundaries at the same y.
    // More robust: check if point is between left and right interpolated x at its y.
    final leftX = _interpolateX(lane.leftBoundary, p.y);
    final rightX = _interpolateX(lane.rightBoundary, p.y);
    if (leftX == null || rightX == null) return false;
    return p.x >= leftX && p.x <= rightX;
  }

  /// Proximity: 0.0 (far) to 1.0 (very close).
  double _computeProximity(Point p) {
    // The lower in the image (higher y), the closer.
    return 1.0 - (p.y / imageHeight).clamp(0.0, 1.0);
  }

  double? _interpolateX(List<Point> boundary, double y) {
    if (boundary.length < 2) return boundary.isNotEmpty ? boundary.first.x : null;
    // Find segment that brackets y
    for (int i = 0; i < boundary.length - 1; i++) {
      final p0 = boundary[i];
      final p1 = boundary[i + 1];
      if ((p0.y <= y && p1.y >= y) || (p0.y >= y && p1.y <= y)) {
        if (p0.y == p1.y) return p0.x;
        final t = (y - p0.y) / (p1.y - p0.y);
        return p0.x + t * (p1.x - p0.x);
      }
    }
    return null;
  }
}