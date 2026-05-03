import 'dart:math' as math;
import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/models/geometry/point.dart';

// ---------------------------------------------------------------------------
// 1-D Kalman filter for a single scalar measurement.
//
// State model: constant position (lane geometry changes slowly).
//
//   Predict:
//     x̂ₖ⁻ = x̂ₖ₋₁              (no motion — lane is assumed stationary)
//     Pₖ⁻  = Pₖ₋₁ + Q           (Q = process noise)
//
//   Update:
//     Kₖ   = Pₖ⁻ / (Pₖ⁻ + R)   (Kalman gain)
//     x̂ₖ   = x̂ₖ⁻ + Kₖ(zₖ−x̂ₖ⁻) (fuse measurement)
//     Pₖ   = (1 − Kₖ) Pₖ⁻
// ---------------------------------------------------------------------------
class _Kalman1D {
  /// Process noise – how much the true value can drift between frames.
  /// Smaller → smoother but slower to react.
  final double q;

  /// Measurement noise – how noisy the raw sensor reading is.
  /// Larger → trust measurements less.
  final double r;

  double _x;   // current state estimate
  double _p;   // current error covariance

  bool _initialised = false;

  _Kalman1D({required this.q, required this.r, double initialP = 1.0})
      : _x = 0.0,
        _p = initialP;

  /// Feed one measurement and get the smoothed estimate back.
  double update(double measurement) {
    if (!_initialised) {
      // Seed state with first measurement to avoid cold-start transient.
      _x = measurement;
      _p = 1.0;
      _initialised = true;
      return _x;
    }

    // --- Predict ---
    final pMinus = _p + q;

    // --- Update ---
    final k = pMinus / (pMinus + r);
    _x = _x + k * (measurement - _x);
    _p = (1.0 - k) * pMinus;

    return _x;
  }

  /// Hard-reset (e.g. after a lane-jump).
  void reset() {
    _initialised = false;
    _x = 0.0;
    _p = 1.0;
  }

  double get estimate => _x;
}

// ---------------------------------------------------------------------------
// 2-D Kalman filter for a Point (x, y treated as independent 1-D filters).
// ---------------------------------------------------------------------------
class _Kalman2D {
  final _Kalman1D _kx;
  final _Kalman1D _ky;

  _Kalman2D({required double q, required double r})
      : _kx = _Kalman1D(q: q, r: r),
        _ky = _Kalman1D(q: q, r: r);

  Point update(Point p) => Point(_kx.update(p.x), _ky.update(p.y));

  void reset() {
    _kx.reset();
    _ky.reset();
  }
}

// ---------------------------------------------------------------------------
// KalmanLaneTracker
//
// Maintains independent Kalman filters for:
//   • laneWidth   (scalar, metres)
//   • curvature   (scalar, m⁻¹)
//   • driftScore  (scalar, metres)
//   • confidence  (scalar, 0-1)
//   • laneCenterX (scalar, world-space lateral mean in metres)
//   • center line points (per-index 2-D filters, resized dynamically)
//   • left boundary points
//   • right boundary points
//
// Usage (inside FrameProcessor):
//
//   final rawLane = _laneEngine.buildLane(detections);
//   final smoothLane = _kalmanTracker.update(rawLane);
//   // use smoothLane for everything downstream
// ---------------------------------------------------------------------------
class KalmanLaneTracker {
  // ── Scalar filters ────────────────────────────────────────────────────────

  /// Lane width (metres) — moderate process noise because roads vary.
  final _kWidth = _Kalman1D(q: 0.02, r: 0.15);

  /// Menger curvature (m⁻¹) — low process noise, roads curve slowly.
  final _kCurvature = _Kalman1D(q: 0.005, r: 0.05);

  /// Drift score (metres) — higher noise, can spike suddenly.
  final _kDrift = _Kalman1D(q: 0.03, r: 0.10);

  /// Confidence — smooth aggressively to damp single bad frames.
  final _kConfidence = _Kalman1D(q: 0.01, r: 0.20);

  /// Lateral position of the lane center (world-space, metres).
  final _kLaneCenterX = _Kalman1D(q: 0.02, r: 0.10);

  // ── Polyline filters ──────────────────────────────────────────────────────
  // Each boundary / center line is a list of Points.
  // We maintain one _Kalman2D per list index.
  // The lists are grown/shrunk to match the current frame's point count.

  final List<_Kalman2D> _centerFilters  = [];
  final List<_Kalman2D> _leftFilters    = [];
  final List<_Kalman2D> _rightFilters   = [];

  // ── Tune-able constants ───────────────────────────────────────────────────
  /// Q for polyline point filters — points move more than scalars.
  static const double _pointQ = 0.5;

  /// R for polyline point filters.
  static const double _pointR = 2.0;

  /// If confidence drops below this, reset filters to avoid locking onto
  /// a stale bad lane.
  static const double _resetThreshold = 0.20;

  /// Maximum point-count change before we discard the old filters and
  /// re-seed (avoids index mis-alignment after lane topology changes).
  static const int _maxCountDelta = 5;

  // ── Jump detection state ──────────────────────────────────────────────────
  LaneModel? _previousLane;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Feed the raw [LaneModel] from [LaneEngine] and receive a temporally
  /// smoothed version. The returned model uses image-space points for
  /// visualisation (unchanged) while the scalar metrics are Kalman-filtered.
  LaneModel update(LaneModel raw) {
    // 1. Detect catastrophic lane jump → hard reset
    if (_shouldReset(raw)) {
      _resetAll();
    }

    // 2. Filter scalars
    final smoothWidth      = _kWidth.update(raw.laneWidth);
    final smoothCurvature  = _kCurvature.update(raw.curvature);
    final smoothDrift      = _kDrift.update(raw.driftScore);
    final smoothConfidence = _kConfidence.update(raw.confidence);

    // 3. Filter world-space lateral center
    final rawCenterX = _lateralMean(raw.centerLine);
    _kLaneCenterX.update(rawCenterX);   // stored internally for virtual lane use

    // 4. Filter polylines
    final smoothCenter = _filterPolyline(raw.centerLine, _centerFilters);
    final smoothLeft   = _filterPolyline(raw.leftBoundary, _leftFilters);
    final smoothRight  = _filterPolyline(raw.rightBoundary, _rightFilters);

    // 5. Build smoothed LaneModel
    final smoothed = LaneModel(
      centerLine:    smoothCenter,
      leftBoundary:  smoothLeft,
      rightBoundary: smoothRight,
      laneWidth:     smoothWidth.clamp(0.0, 10.0),      // sanity clamp (metres)
      confidence:    smoothConfidence.clamp(0.0, 1.0),
      driftScore:    smoothDrift.clamp(0.0, 5.0),
      curvature:     smoothCurvature.clamp(0.0, 1.0),
      type:          raw.type,
    );

    _previousLane = smoothed;
    return smoothed;
  }

  /// Expose the smoothed lateral lane-center estimate (metres, world-space).
  /// Used by [VirtualLaneGenerator] to project forward when markings are lost.
  double get smoothedLaneCenterX => _kLaneCenterX.estimate;

  /// Expose smoothed lane width (metres).
  double get smoothedLaneWidth => _kWidth.estimate;

  /// Expose smoothed curvature (m⁻¹).
  double get smoothedCurvature => _kCurvature.estimate;

  /// Last smoothed lane — used by [VirtualLaneGenerator] as fallback geometry.
  LaneModel? get lastSmoothedLane => _previousLane;

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Filter a list of [Point]s using a pool of [_Kalman2D] filters.
  /// Grows or resets the pool when the list length changes significantly.
  List<Point> _filterPolyline(List<Point> raw, List<_Kalman2D> pool) {
    if (raw.isEmpty) return [];

    final delta = (raw.length - pool.length).abs();

    if (pool.isEmpty || delta > _maxCountDelta) {
      // Re-seed: create fresh filters and initialise with raw values.
      pool.clear();
      for (final p in raw) {
        final f = _Kalman2D(q: _pointQ, r: _pointR);
        f.update(p); // seed on first call
        pool.add(f);
      }
      return List<Point>.from(raw);
    }

    // Resize pool to match raw (trim or extend).
    while (pool.length > raw.length) pool.removeLast();
    while (pool.length < raw.length) {
      pool.add(_Kalman2D(q: _pointQ, r: _pointR));
    }

    // Filter each point.
    return [
      for (int i = 0; i < raw.length; i++) pool[i].update(raw[i]),
    ];
  }

  /// Compute the mean x-coordinate (lateral position) of a polyline.
  double _lateralMean(List<Point> pts) {
    if (pts.isEmpty) return 0.0;
    return pts.map((p) => p.x).reduce((a, b) => a + b) / pts.length;
  }

  /// Decide whether to hard-reset all filters.
  ///
  /// Resets when:
  ///  • Confidence collapses (bad detection)
  ///  • Center line jumps more than [_jumpThresholdPx] pixels
  bool _shouldReset(LaneModel raw) {
    // Confidence floor
    if (raw.confidence < _resetThreshold) return true;

    // Geometric jump
    if (_previousLane != null &&
        raw.centerLine.isNotEmpty &&
        _previousLane!.centerLine.isNotEmpty) {
      // Compare bottom-most point (closest to vehicle, most stable)
      final prev = _previousLane!.centerLine.last;
      final curr = raw.centerLine.last;
      final dist = math.sqrt(
        math.pow(curr.x - prev.x, 2) + math.pow(curr.y - prev.y, 2),
      );
      if (dist > _jumpThresholdPx) return true;
    }

    return false;
  }

  /// Pixel jump that triggers a hard reset.
  /// 60px at 640-wide frame ≈ ~9% of frame width.
  static const double _jumpThresholdPx = 60.0;

  void _resetAll() {
    _kWidth.reset();
    _kCurvature.reset();
    _kDrift.reset();
    _kConfidence.reset();
    _kLaneCenterX.reset();
    _centerFilters.clear();
    _leftFilters.clear();
    _rightFilters.clear();
    _previousLane = null;
  }
}