import 'dart:math' as math;
import '../../data/runtime/models/detection_model.dart';
import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/models/geometry/point.dart';
import '../../data/domain/enums.dart';
import '../../core/utils/camera_calibration.dart';

/// Typedef for world coordinate points (metres)
typedef WorldPoint = ({double forward, double left});

class LaneEngine {
  final DynamicCalibration calibration;

  LaneEngine(this.calibration);

  LaneModel buildLane(List<DetectionModel> detections) {
    // --- 1. Filter detections (unchanged) ---
    final roadSurface = _filter(detections, "road_surface");
    final edges = _filter(detections, "road_edge");
    final centerLines = _filter(detections, "center_line_marking");

    // --- 2. Build road corridor (unchanged) ---
    final corridor = _buildRoadCorridor(roadSurface, edges);

    // --- 3. Compute image‑space boundaries ---
    final boundaries = _computeBoundaries(corridor, edges);
    List<Point> leftBoundary = boundaries.$1;
    List<Point> rightBoundary = boundaries.$2;

    // --- 4. Image‑space centre line ---
    List<Point> centerLine = _computeCenterLine(boundaries, centerLines);

    // --- 5. Dynamic vanishing point & calibration update ---
    double? vanishingY;
    if (leftBoundary.length >= 2 && rightBoundary.length >= 2) {
      vanishingY = _estimateVanishingY(leftBoundary, rightBoundary);
    } else if (centerLine.length >= 2) {
      vanishingY = _estimateVanishingYFromCenter(centerLine);
    }

    if (vanishingY != null) {
      calibration.updateFromLane(vanishingY);
    }

    // --- 6. Transform to world coordinates ---
    final WorldPoints worldCenter = calibration.pointsToWorld(centerLine);
    final WorldPoints worldLeft = calibration.pointsToWorld(leftBoundary);
    final WorldPoints worldRight = calibration.pointsToWorld(rightBoundary);

    // --- 7. Compute real‑world metrics ---
    final double laneWidth = _computeRealLaneWidth(worldLeft, worldRight);
    final double curvature = _computeRealCurvature(worldCenter);
    final double driftScore = _computeRealDrift(worldCenter);
    final double confidence = _computeConfidence(detections);

    return LaneModel(
      centerLine: centerLine,        // keep image points for visualisation
      leftBoundary: leftBoundary,
      rightBoundary: rightBoundary,
      laneWidth: laneWidth,          // now in metres
      confidence: confidence,
      driftScore: driftScore,
      curvature: curvature,          // in m⁻¹
      type: _classifyLaneType(laneWidth, curvature),
    );
  }

  // ------------------------------------------------------------
  // Real‑world metric implementations
  // ------------------------------------------------------------

  /// Average lane width in metres.
  double _computeRealLaneWidth(WorldPoints left, WorldPoints right) {
    
    if (left.isEmpty || right.isEmpty) return 0;
    
    double sum = 0;
    int count = 0;
    
    final len = math.min(left.length, right.length);
    for (int i = 0; i < len; i++) {
      sum += (right[i].left - left[i].left).abs();
      count++;
    }
    return count > 0 ? sum / count : 0;
  }

  /// Menger curvature averaged over all point triplets.
  /// 
  /// curvature = 4 * area(ABC) / (d_AB * d_BC * d_AC)
  /// 
  /// where 
  ///   area(ABC) = 0.5 * | (Bx-Ax)*(Cy-Ay) - (By-Ay)*(Cx-Ax) |
  ///   d_XY = Euclidean distance between X and Y
  ///
  /// Returns the mean absolute curvature in 1/metres.
  /// Returns 0 if not enough points.
  double _computeRealCurvature(WorldPoints points) {
    if (points.length < 3) return 0;

    double totalCurvature = 0;
    int count = 0;

    for (int i = 0; i < points.length - 2; i++) {
      final a = points[i];
      final b = points[i + 1];
      final c = points[i + 2];

      // Euclidean distances
      final ab = _distance(a, b);
      final bc = _distance(b, c);
      final ac = _distance(a, c);

      // Avoid division by zero
      if (ab < 1e-6 || bc < 1e-6 || ac < 1e-6) continue;

      // Area of triangle using cross product (2D)
      final double cross =
          (b.forward - a.forward) * (c.left - a.left) -
          (b.left - a.left) * (c.forward - a.forward);
      final double area = 0.5 * cross.abs();

      // Menger curvature: 4 * area / (ab * bc * ac)
      final double curvature = (4 * area) / (ab * bc * ac);

      totalCurvature += curvature;
      count++;
    }

    return count > 0 ? totalCurvature / count : 0;
  }

  /// Lateral drift score: standard deviation of lateral positions (metres).
  double _computeRealDrift(WorldPoints points) {
  
    if (points.length < 2) return 0;
    
    final meanLeft =
        points.map((p) => p.left).reduce((a, b) => a + b) / points.length;
    
    final variance = points
        .map((p) => (p.left - meanLeft) * (p.left - meanLeft))
        .reduce((a, b) => a + b) /
        points.length;
    
    return math.sqrt(variance); // in m² – small means stable
  }

  double _distance(WorldPoint a, WorldPoint b) {
    final df = a.forward - b.forward;
    final dl = a.left - b.left;
    return math.sqrt(df * df + dl * dl);
  }

  // ------------------------------------------------------------
  // Confidence (unchanged)
  // ------------------------------------------------------------
  double _computeConfidence(List<DetectionModel> detections) {
   
    if (detections.isEmpty) return 0;
    
    return detections.map((d) => d.confidence).reduce((a, b) => a + b) /
        detections.length;
  }

  // ------------------------------------------------------------
  // Vanishing point estimation (helper for dynamic calibration)
  // ------------------------------------------------------------
  double _estimateVanishingY(List<Point> left, List<Point> right) {
    final p1 = left.first, p2 = left.last;
    final p3 = right.first, p4 = right.last;
    final det = (p1.x - p2.x) * (p3.y - p4.y) - (p1.y - p2.y) * (p3.x - p4.x);
    
    if (det.abs() < 1e-6) return calibration.principalY; // parallel
    
    final t = ((p1.x - p3.x) * (p3.y - p4.y) - (p1.y - p3.y) * (p3.x - p4.x)) /
        det;
    
    return p1.y + t * (p2.y - p1.y);
  }

  double _estimateVanishingYFromCenter(List<Point> center) {
    final p1 = center.first, p2 = center.last;
    
    return p1.y + (p2.y - p1.y) * 2; // rough extrapolation
  }

  // ------------------------------------------------------------
  // Lane type classification (stub – will be improved later)
  // ------------------------------------------------------------
  LaneType _classifyLaneType(double width, double curvature) {
    // Example: if curvature is high (sharp turn) and width is narrow -> rural?
    return LaneType.virtual;
  }

  // ------------------------------------------------------------
  // Original image‑space detection helpers (unchanged)
  // ------------------------------------------------------------
  List<DetectionModel> _filter(List<DetectionModel> list, String className) {
    
    return list.where((d) => d.className == className).toList();
  }

  List<Point> _buildRoadCorridor(
      List<DetectionModel> road, List<DetectionModel> edges) {
   
    final points = <Point>[];
    for (final r in road) {
      points.addAll(r.mask);
    }

    for (final e in edges) {
      points.addAll(e.mask);
    }
    return points;
  }

  (List<Point>, List<Point>) _computeBoundaries(
      List<Point> corridor, List<DetectionModel> edges) {
   
    if (edges.length >= 2) {
      edges.sort((a, b) => _avgX(a.mask).compareTo(_avgX(b.mask)));
      return (edges.first.mask, edges.last.mask);
    }

    if (corridor.isEmpty) return ([], []);

    final sorted = List<Point>.from(corridor)
      ..sort((a, b) => a.x.compareTo(b.x));

    final midX = _medianX(sorted);
    final left = <Point>[], right = <Point>[];

    for (final p in sorted) {
      if (p.x < midX) left.add(p); else right.add(p);
    }

    return (left, right);
  }

  double _avgX(List<Point> pts) {
    if (pts.isEmpty) return 0.0;   // or throw a meaningful error
    return pts.fold(0.0, (sum, p) => sum + p.x) / pts.length;
  }

  double _medianX(List<Point> points) {
    final xs = points.map((e) => e.x).toList()..sort();
    
    return xs[xs.length ~/ 2];
  }

  List<Point> _computeCenterLine(
    (List<Point>, List<Point>) boundaries,
    List<DetectionModel> centerLines,
  ) {
    final left = boundaries.$1;
    final right = boundaries.$2;
    if (left.isEmpty || right.isEmpty) return _fallbackCenter(centerLines);

    // Sort both boundaries by y (ascending, from top to bottom)
    final sortedLeft = List<Point>.from(left)..sort((a, b) => a.y.compareTo(b.y));
    final sortedRight = List<Point>.from(right)..sort((a, b) => a.y.compareTo(b.y));

    // Create a unified set of y levels by merging unique y's
    final allY = <double>{};
    for (final p in sortedLeft) allY.add(p.y);
    for (final p in sortedRight) allY.add(p.y);
    final yValues = allY.toList()..sort();

    final center = <Point>[];
    for (final y in yValues) {
      // Interpolate left x at this y
      double? leftX = _interpolateX(sortedLeft, y);
      double? rightX = _interpolateX(sortedRight, y);
      if (leftX != null && rightX != null) {
        center.add(Point((leftX + rightX) / 2, y));
      }
    }

    return center.isEmpty ? _fallbackCenter(centerLines) : center;
  }

  double? _interpolateX(List<Point> points, double y) {
    if (points.isEmpty) return null;

    // Find the two points that bracket y
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      if ((p0.y <= y && p1.y >= y) || (p0.y >= y && p1.y <= y)) {
        
        if (p0.y == p1.y) return p0.x; // avoid division by zero
        final t = (y - p0.y) / (p1.y - p0.y);
        return p0.x + t * (p1.x - p0.x);
      }
    }
    // If outside range, clamp to nearest endpoint
    if (y < points.first.y) return points.first.x;
    if (y > points.last.y) return points.last.x;
    return null;
  }

  List<Point> _fallbackCenter(List<DetectionModel> centerLines) {
    
    final points = <Point>[];
    for (final c in centerLines) {
      points.addAll(c.mask);
    }
    
    return points;
  }
}

// Helper typedef to simplify world point lists
typedef WorldPoints = List<({double forward, double left})>;