import 'dart:math' as math;
import '../../data/runtime/models/lane_model.dart';
import '../../data/runtime/models/detection_model.dart';
import '../../data/domain/models/geometry/point.dart';
import '../../data/domain/enums.dart';
import '../../data/runtime/models/geo_data.dart';
import 'kalman_lane_tracker.dart';

// ---------------------------------------------------------------------------
// VirtualLaneGenerator
//
// Called when [LaneEngine] returns a low-confidence or empty lane.
// Synthesises a plausible [LaneModel] using (in priority order):
//
//   Strategy 1 — Two road edges detected
//     → center = midpoint of the two edges
//     → width  = distance between edges
//
//   Strategy 2 — One road edge detected
//     → offset by [historicalWidth] to the opposite side
//
//   Strategy 3 — No edges, but Kalman has a prior lane
//     → project last known center line forward by [_projectionSteps] pixels
//        using the last known heading delta (curvature proxy)
//
//   Strategy 4 — Nothing at all
//     → return null (FrameProcessor skips geometry-dependent steps)
//
// All virtual lanes get:
//   • type = LaneType.virtual
//   • confidence reduced (≤ 0.35) so downstream engines treat it as uncertain
// ---------------------------------------------------------------------------
class VirtualLaneGenerator {
  /// Confidence threshold below which we attempt virtual generation.
  static const double triggerThreshold = 0.35;

  /// Confidence assigned to a strategy-1/2 virtual lane (edge-derived).
  static const double _edgeConfidence = 0.30;

  /// Confidence assigned to a strategy-3 virtual lane (projection-derived).
  static const double _projectionConfidence = 0.18;

  /// How many synthetic points to generate along the projected center line.
  static const int _projectionSteps = 12;

  /// Assumed minimum lane width when no historical data is available (metres).
  static const double _fallbackWidthM = 3.0;

  final KalmanLaneTracker _kalman;

  VirtualLaneGenerator(this._kalman);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Attempt to generate a virtual lane.
  ///
  /// [raw]          : the low-confidence lane from LaneEngine (may be empty)
  /// [detections]   : full detection list (we look for road_edge here)
  /// [historicalWidthM] : avgLaneWidth from RoadSegments DB (null if unknown)
  /// [geo]          : current GPS fix (used for heading-based projection)
  ///
  /// Returns null if no strategy can produce a plausible lane.
  LaneModel? generate({
    required LaneModel raw,
    required List<DetectionModel> detections,
    double? historicalWidthM,
    GeoData? geo,
  }) {
    final effectiveWidth =
        historicalWidthM ?? _kalman.smoothedLaneWidth.clamp(2.5, 5.0);

    // Prefer non-zero historical width, fall back to default
    final width = (effectiveWidth > 0.5) ? effectiveWidth : _fallbackWidthM;

    // Strategy 1 & 2: road edge detections
    final edges = detections
        .where((d) => d.className == 'road_edge')
        .toList();

    if (edges.length >= 2) {
      return _fromTwoEdges(edges, width);
    }

    if (edges.length == 1) {
      return _fromOneEdge(edges.first, width, raw);
    }

    // Strategy 3: project from Kalman prior
    final prior = _kalman.lastSmoothedLane;
    if (prior != null && prior.centerLine.isNotEmpty) {
      return _projectFromPrior(prior, width, geo);
    }

    // Strategy 4: give up
    return null;
  }

  // ── Strategy 1: two edges ─────────────────────────────────────────────────

  LaneModel _fromTwoEdges(List<DetectionModel> edges, double width) {
    // Sort edges left → right by their average x
    edges.sort((a, b) => _avgX(a.mask).compareTo(_avgX(b.mask)));

    final leftPts  = _sortByY(edges.first.mask);
    final rightPts = _sortByY(edges.last.mask);

    final center = _midPolyline(leftPts, rightPts);

    // Measure actual pixel-space width from edges
    final measuredWidth = _polylineWidth(leftPts, rightPts);

    return LaneModel(
      centerLine:    center,
      leftBoundary:  leftPts,
      rightBoundary: rightPts,
      laneWidth:     measuredWidth > 0 ? measuredWidth : width,
      confidence:    _edgeConfidence,
      driftScore:    0.0,   // virtual — drift undefined
      curvature:     _estimateCurvature(center),
      type:          LaneType.virtual,
    );
  }

  // ── Strategy 2: one edge ──────────────────────────────────────────────────

  LaneModel _fromOneEdge(
    DetectionModel edge,
    double widthM,
    LaneModel raw,
  ) {
    // Convert width from metres to approximate pixels.
    // Use Kalman smoothed width if we have it.
    final widthPx = _metresToPixels(widthM);

    final edgePts = _sortByY(edge.mask);
    if (edgePts.isEmpty) return _emptyVirtualLane();

    final edgeAvgX = _avgX(edgePts);

    // Decide which side the edge is on by comparing to frame center (320px).
    final isLeftEdge = edgeAvgX < 320.0;

    List<Point> left, right, center;

    if (isLeftEdge) {
      left   = edgePts;
      right  = edgePts.map((p) => Point(p.x + widthPx, p.y)).toList();
    } else {
      right  = edgePts;
      left   = edgePts.map((p) => Point(p.x - widthPx, p.y)).toList();
    }

    center = _midPolyline(left, right);

    return LaneModel(
      centerLine:    center,
      leftBoundary:  left,
      rightBoundary: right,
      laneWidth:     widthM,
      confidence:    _edgeConfidence * 0.8,   // slightly less than strategy 1
      driftScore:    0.0,
      curvature:     _estimateCurvature(center),
      type:          LaneType.virtual,
    );
  }

  // ── Strategy 3: project Kalman prior forward ──────────────────────────────

  LaneModel _projectFromPrior(
    LaneModel prior,
    double widthM,
    GeoData? geo,
  ) {
    final pts = prior.centerLine;
    if (pts.length < 2) return _emptyVirtualLane();

    // Estimate direction from the last two center-line points
    final p1 = pts[pts.length - 2];
    final p2 = pts.last;

    final dx = p2.x - p1.x;
    final dy = p2.y - p1.y;
    final len = math.sqrt(dx * dx + dy * dy);

    if (len < 1e-6) return _emptyVirtualLane();

    // Unit direction vector
    final ux = dx / len;
    final uy = dy / len;

    // Project [_projectionSteps] points forward along this direction
    const stepPx = 8.0;
    final center = <Point>[];
    for (int i = 1; i <= _projectionSteps; i++) {
      center.add(Point(
        p2.x + ux * stepPx * i,
        p2.y + uy * stepPx * i,
      ));
    }

    // Perpendicular offset for left/right
    final halfW = _metresToPixels(widthM) / 2;
    final px = -uy;  // perpendicular x
    final py =  ux;  // perpendicular y

    final left  = center.map((p) => Point(p.x - px * halfW, p.y - py * halfW)).toList();
    final right = center.map((p) => Point(p.x + px * halfW, p.y + py * halfW)).toList();

    return LaneModel(
      centerLine:    center,
      leftBoundary:  left,
      rightBoundary: right,
      laneWidth:     widthM,
      confidence:    _projectionConfidence,
      driftScore:    prior.driftScore,
      curvature:     prior.curvature,
      type:          LaneType.virtual,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Convert world-space metres to approximate image pixels.
  /// Uses a rough pixel-per-metre estimate for the bottom of a 640-wide frame.
  /// This will be replaced with proper IPM if calibration is available.
  static const double _pixelsPerMetre = 80.0; // approximate — tune per device

  double _metresToPixels(double metres) => metres * _pixelsPerMetre;

  double _avgX(List<Point> pts) {
    if (pts.isEmpty) return 320.0;
    return pts.map((p) => p.x).reduce((a, b) => a + b) / pts.length;
  }

  List<Point> _sortByY(List<Point> pts) =>
      List<Point>.from(pts)..sort((a, b) => a.y.compareTo(b.y));

  /// Build a center line as the midpoint between two sorted polylines.
  List<Point> _midPolyline(List<Point> left, List<Point> right) {
    if (left.isEmpty || right.isEmpty) return [];
    final n = math.min(left.length, right.length);
    return [
      for (int i = 0; i < n; i++)
        Point((left[i].x + right[i].x) / 2, (left[i].y + right[i].y) / 2),
    ];
  }

  /// Average pixel distance between paired left/right boundary points.
  double _polylineWidth(List<Point> left, List<Point> right) {
    if (left.isEmpty || right.isEmpty) return 0;
    final n = math.min(left.length, right.length);
    double sum = 0;
    for (int i = 0; i < n; i++) {
      sum += (right[i].x - left[i].x).abs();
    }
    return sum / n;
  }

  /// Simple curvature estimate from first / mid / last center point.
  double _estimateCurvature(List<Point> pts) {
    if (pts.length < 3) return 0;
    final s = pts.first;
    final m = pts[pts.length ~/ 2];
    final e = pts.last;
    return ((s.x - 2 * m.x + e.x).abs() + (s.y - 2 * m.y + e.y).abs()) /
        (pts.length * 10.0);
  }

  LaneModel _emptyVirtualLane() => const LaneModel(
        centerLine:    [],
        leftBoundary:  [],
        rightBoundary: [],
        laneWidth:     0,
        confidence:    0,
        driftScore:    0,
        curvature:     0,
        type:          LaneType.virtual,
      );
}