import 'dart:math' as math;
import '../../data/runtime/models/detection_model.dart';
import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/models/geometry/point.dart';
import '../../data/domain/enums.dart';
import '../../core/utils/camera_calibration.dart';

typedef WorldPoint  = ({double forward, double left});
typedef WorldPoints = List<({double forward, double left})>;

class LaneEngine {
  final DynamicCalibration calibration;

  LaneEngine(this.calibration);

  LaneModel buildLane(List<DetectionModel> detections) {
    final roadSurface = _filter(detections, 'road_surface');
    final edges       = _filter(detections, 'road_edge');
    final centerLines = _filter(detections, 'center_line_marking');

    final corridor = _buildRoadCorridor(roadSurface, edges);

    final boundaries   = _computeBoundaries(corridor, edges);
    List<Point> leftBoundary  = boundaries.$1;
    List<Point> rightBoundary = boundaries.$2;

    List<Point> centerLine = _computeCenterLine(boundaries, centerLines);

    // Dynamic vanishing point
    double? vanishingY;
    if (leftBoundary.length >= 2 && rightBoundary.length >= 2) {
      vanishingY = _estimateVanishingY(leftBoundary, rightBoundary);
    } else if (centerLine.length >= 2) {
      vanishingY = _estimateVanishingYFromCenter(centerLine);
    }
    if (vanishingY != null) calibration.updateFromLane(vanishingY);

    // World-space metrics
    final worldCenter = calibration.pointsToWorld(centerLine);
    final worldLeft   = calibration.pointsToWorld(leftBoundary);
    final worldRight  = calibration.pointsToWorld(rightBoundary);

    final laneWidth  = _computeRealLaneWidth(worldLeft, worldRight);
    final curvature  = _computeRealCurvature(worldCenter);
    final driftScore = _computeRealDrift(worldCenter);
    final confidence = _computeConfidence(detections);

    return LaneModel(
      centerLine:    centerLine,
      leftBoundary:  leftBoundary,
      rightBoundary: rightBoundary,
      laneWidth:     laneWidth,
      confidence:    confidence,
      driftScore:    driftScore,
      curvature:     curvature,
      type:          _classifyLaneType(laneWidth, curvature),
    );
  }

  // ── Boundary computation ──────────────────────────────────────────────────

  (List<Point>, List<Point>) _computeBoundaries(
    List<Point> corridor,
    List<DetectionModel> edges,
  ) {
    // ── Strategy 1: use road_edge detections ─────────────────────────────
    if (edges.isNotEmpty) {
      // Each edge detection's mask is a contour polygon — not a sorted
      // top-to-bottom polyline.  We need to convert it into one.
      final edgeLines = edges
          .where((e) => e.mask.length >= 2)
          .map((e) => _maskToSortedPolyline(e.mask))
          .where((pts) => pts.length >= 2)
          .toList();

      if (edgeLines.length >= 2) {
        // Sort edges left → right by their horizontal centroid
        edgeLines.sort((a, b) => _avgX(a).compareTo(_avgX(b)));
        return (edgeLines.first, edgeLines.last);
      }

      if (edgeLines.length == 1) {
        // Only one edge: mirror it to produce both boundaries
        final edge = edgeLines.first;
        final edgeMid = _avgX(edge);
        final frameMid = 320.0; // half of 640
        if (edgeMid < frameMid) {
          // It's the left edge — synthesise the right by reflection
          final right = edge.map((p) => Point(frameMid + (frameMid - p.x), p.y)).toList();
          return (edge, right);
        } else {
          // It's the right edge — synthesise the left
          final left = edge.map((p) => Point(frameMid - (p.x - frameMid), p.y)).toList();
          return (left, edge);
        }
      }
    }

    // ── Strategy 2: split road corridor at the median X ──────────────────
    if (corridor.isEmpty) return ([], []);

    final sorted = List<Point>.from(corridor)
      ..sort((a, b) => a.x.compareTo(b.x));

    final midX = _medianX(sorted);
    final left  = <Point>[];
    final right = <Point>[];

    for (final p in sorted) {
      if (p.x < midX) left.add(p); else right.add(p);
    }

    return (
      _maskToSortedPolyline(left),
      _maskToSortedPolyline(right),
    );
  }

  /// Converts an unordered mask polygon into a top-to-bottom sorted polyline.
  ///
  /// A YOLOv8 segmentation contour is a polygon — the points run around the
  /// perimeter and are not ordered top-to-bottom.  For lane boundary use, we
  /// need a vertical spine (the left or right edge of the contour), so we:
  ///   1. Sort all points by Y (top → bottom).
  ///   2. For each Y-band, keep only the leftmost or rightmost point.
  ///   3. Return the resulting sparse but monotonic polyline.
  List<Point> _maskToSortedPolyline(List<Point> mask) {
    if (mask.length < 2) return mask;

    // Sort by Y ascending (top of image first)
    final sorted = List<Point>.from(mask)
      ..sort((a, b) => a.y.compareTo(b.y));

    // Thin the polyline: for nearby Y values, keep one representative point.
    // We bucket by every 4 pixels of Y to avoid huge point counts.
    const double bucketSize = 4.0;
    final buckets = <int, List<Point>>{};
    for (final p in sorted) {
      final key = (p.y / bucketSize).floor();
      buckets.putIfAbsent(key, () => []).add(p);
    }

    // From each bucket pick the median-X point (more stable than min/max)
    final result = <Point>[];
    final keys = buckets.keys.toList()..sort();
    for (final k in keys) {
      final pts = buckets[k]!..sort((a, b) => a.x.compareTo(b.x));
      result.add(pts[pts.length ~/ 2]);
    }

    return result;
  }

  // ── Center line ───────────────────────────────────────────────────────────

  List<Point> _computeCenterLine(
    (List<Point>, List<Point>) boundaries,
    List<DetectionModel> centerLines,
  ) {
    final left  = boundaries.$1;
    final right = boundaries.$2;

    if (left.isEmpty || right.isEmpty) return _fallbackCenter(centerLines);

    // Both boundaries are now sorted by Y — interpolate a midpoint per Y level.
    final allY = <double>{};
    for (final p in left)  allY.add(p.y);
    for (final p in right) allY.add(p.y);
    final yValues = allY.toList()..sort();

    final center = <Point>[];
    for (final y in yValues) {
      final leftX  = _interpolateX(left,  y);
      final rightX = _interpolateX(right, y);
      if (leftX != null && rightX != null) {
        center.add(Point((leftX + rightX) / 2, y));
      }
    }

    return center.isEmpty ? _fallbackCenter(centerLines) : center;
  }

  List<Point> _fallbackCenter(List<DetectionModel> centerLines) {
    final points = <Point>[];
    for (final c in centerLines) points.addAll(c.mask);
    // Sort the fallback by Y too
    points.sort((a, b) => a.y.compareTo(b.y));
    return points;
  }

  // ── Real-world metrics ────────────────────────────────────────────────────

  double _computeRealLaneWidth(WorldPoints left, WorldPoints right) {
    if (left.isEmpty || right.isEmpty) return 0;
    double sum = 0;
    int count  = 0;
    final len  = math.min(left.length, right.length);
    for (int i = 0; i < len; i++) {
      sum += (right[i].left - left[i].left).abs();
      count++;
    }
    return count > 0 ? sum / count : 0;
  }

  double _computeRealCurvature(WorldPoints points) {
    if (points.length < 3) return 0;
    double total = 0;
    int    count = 0;
    for (int i = 0; i < points.length - 2; i++) {
      final a = points[i], b = points[i + 1], c = points[i + 2];
      final ab = _dist(a, b), bc = _dist(b, c), ac = _dist(a, c);
      if (ab < 1e-6 || bc < 1e-6 || ac < 1e-6) continue;
      final cross = (b.forward - a.forward) * (c.left - a.left)
                  - (b.left    - a.left)    * (c.forward - a.forward);
      final area  = 0.5 * cross.abs();
      total += (4 * area) / (ab * bc * ac);
      count++;
    }
    return count > 0 ? total / count : 0;
  }

  double _computeRealDrift(WorldPoints points) {
    if (points.length < 2) return 0;
    final mean = points.map((p) => p.left).reduce((a, b) => a + b) / points.length;
    final variance = points
        .map((p) => (p.left - mean) * (p.left - mean))
        .reduce((a, b) => a + b) / points.length;
    return math.sqrt(variance);
  }

  double _dist(WorldPoint a, WorldPoint b) {
    final df = a.forward - b.forward;
    final dl = a.left    - b.left;
    return math.sqrt(df * df + dl * dl);
  }

  double _computeConfidence(List<DetectionModel> detections) {
    if (detections.isEmpty) return 0;
    return detections.map((d) => d.confidence).reduce((a, b) => a + b) /
        detections.length;
  }

  // ── Vanishing point ───────────────────────────────────────────────────────

  double _estimateVanishingY(List<Point> left, List<Point> right) {
    final p1 = left.first,  p2 = left.last;
    final p3 = right.first, p4 = right.last;
    final det = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
    if (det.abs() < 1e-6) return calibration.principalY;
    final t = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) / det;
    return p1.y + t * (p2.y - p1.y);
  }

  double _estimateVanishingYFromCenter(List<Point> center) {
    final p1 = center.first, p2 = center.last;
    return p1.y + (p2.y - p1.y) * 2;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  LaneType _classifyLaneType(double width, double curvature) {
    if (width <= 0)          return LaneType.virtual;
    if (curvature > 0.1)     return LaneType.inferred;
    if (width < 2.5)         return LaneType.broken;
    return LaneType.solid;
  }

  List<DetectionModel> _filter(List<DetectionModel> list, String className) =>
      list.where((d) => d.className == className).toList();

  List<Point> _buildRoadCorridor(
      List<DetectionModel> road, List<DetectionModel> edges) {
    final points = <Point>[];
    for (final r in road)  points.addAll(r.mask);
    for (final e in edges) points.addAll(e.mask);
    return points;
  }

  double _avgX(List<Point> pts) {
    if (pts.isEmpty) return 0;
    return pts.fold(0.0, (s, p) => s + p.x) / pts.length;
  }

  double _medianX(List<Point> points) {
    final xs = points.map((e) => e.x).toList()..sort();
    return xs[xs.length ~/ 2];
  }

  double? _interpolateX(List<Point> points, double y) {
    if (points.isEmpty) return null;
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i], p1 = points[i + 1];
      if ((p0.y <= y && p1.y >= y) || (p0.y >= y && p1.y <= y)) {
        if (p0.y == p1.y) return p0.x;
        final t = (y - p0.y) / (p1.y - p0.y);
        return p0.x + t * (p1.x - p0.x);
      }
    }
    if (y < points.first.y) return points.first.x;
    if (y > points.last.y)  return points.last.x;
    return null;
  }
}