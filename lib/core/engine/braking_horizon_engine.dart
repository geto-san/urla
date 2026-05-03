import 'dart:math' as math;
import '../../data/runtime/models/obstacle_model.dart';
import '../../data/runtime/models/geo_data.dart';
import '../../data/runtime/models/lane_model.dart';
import '../utils/camera_calibration.dart';

// ---------------------------------------------------------------------------
// BrakingUrgency
// ---------------------------------------------------------------------------
enum BrakingUrgency {
  /// Safe — plenty of room to stop comfortably.
  safe,

  /// Caution — tighter than ideal but no immediate action needed.
  caution,

  /// Warning — begin braking, closing fast.
  warning,

  /// Critical — immediate hard braking required.
  critical,
}

// ---------------------------------------------------------------------------
// BrakingState
//
// The output of [BrakingHorizonEngine.evaluate()].
// Consumed by [OutputCoordinator] for TTS + haptic decisions.
// ---------------------------------------------------------------------------
class BrakingState {
  /// Overall urgency level.
  final BrakingUrgency urgency;

  /// Estimated stopping distance for current speed and road conditions (m).
  /// Returns double.infinity when speed is essentially zero.
  final double stoppingDistanceM;

  /// Estimated time-to-impact based on current speed and obstacle distance (s).
  /// Returns double.infinity when obstacle is absent or very far.
  final double timeToImpactS;

  /// Estimated distance to the obstacle (m).
  /// Returns double.infinity when not computable.
  final double obstacleDistanceM;

  /// Safety ratio: obstacleDistance / stoppingDistance.
  /// > 2.0 = safe, 1.2–2.0 = caution, 0.8–1.2 = warning, < 0.8 = critical.
  final double safetyRatio;

  const BrakingState({
    required this.urgency,
    required this.stoppingDistanceM,
    required this.timeToImpactS,
    required this.obstacleDistanceM,
    required this.safetyRatio,
  });

  /// Safe default when no obstacle is present.
  factory BrakingState.safe() => const BrakingState(
        urgency:            BrakingUrgency.safe,
        stoppingDistanceM:  double.infinity,
        timeToImpactS:      double.infinity,
        obstacleDistanceM:  double.infinity,
        safetyRatio:        double.infinity,
      );

  bool get isCritical => urgency == BrakingUrgency.critical;
  bool get isWarning   => urgency == BrakingUrgency.warning || isCritical;
}

// ---------------------------------------------------------------------------
// BrakingHorizonEngine
//
// Physics model:
//   Stopping distance = v² / (2 · μ · g)
//     where μ = surface friction coefficient
//           g = 9.81 m/s²
//
// Obstacle distance is estimated from the normalised proximity value
// produced by [ObstacleEngine]:
//   proximity ∈ [0, 1] where 1 = very close
//
// We convert proximity → metres using the camera geometry:
//   y_image = principalY + focalY · (cameraHeight / distance) · cos(pitch)
// Rearranged for distance given an image y.
//
// Additionally we apply a curvature penalty: on curved roads the effective
// safe stopping distance grows because the driver cannot see ahead as far.
// ---------------------------------------------------------------------------
class BrakingHorizonEngine {
  final DynamicCalibration _calibration;

  /// Friction coefficient for dry tarmac.
  static const double _muDry   = 0.70;

  /// Friction coefficient for wet / muddy road.
  static const double _muWet   = 0.35;

  /// Gravity (m/s²).
  static const double _g = 9.81;

  /// Minimum speed below which we skip braking calculations (stationary).
  static const double _minSpeedMs = 0.5; // 0.5 m/s ≈ 1.8 km/h

  /// Curvature threshold above which we apply a visibility penalty.
  static const double _curvatureThreshold = 0.04; // m⁻¹

  BrakingHorizonEngine(this._calibration);

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Evaluate the braking horizon for the current frame.
  ///
  /// [obstacle]  : from ObstacleEngine
  /// [geo]       : current GPS fix (provides speed)
  /// [lane]      : for curvature penalty
  /// [wetRoad]   : set to true when rain / poor surface is detected
  ///               (future: derive from environment classification)
  BrakingState evaluate({
    required ObstacleState obstacle,
    required GeoData geo,
    required LaneModel lane,
    bool wetRoad = false,
  }) {
    // No obstacle → trivially safe.
    if (!obstacle.obstacleAhead) return BrakingState.safe();

    final speedMs = geo.speed.abs();

    // Stationary vehicle — cannot determine time to impact.
    if (speedMs < _minSpeedMs) {
      return BrakingState(
        urgency:            BrakingUrgency.caution,
        stoppingDistanceM:  0,
        timeToImpactS:      double.infinity,
        obstacleDistanceM:  _proximityToDistance(obstacle.proximity),
        safetyRatio:        double.infinity,
      );
    }

    // 1. Stopping distance (kinematic, flat road)
    final mu = wetRoad ? _muWet : _muDry;
    double stopDist = (speedMs * speedMs) / (2.0 * mu * _g);

    // 2. Curvature visibility penalty
    //    On a curved road, safe stopping distance is reduced because the
    //    driver's sight-line is shorter. We shrink the "safe" threshold
    //    proportionally to curvature above the threshold.
    if (lane.curvature > _curvatureThreshold) {
      final excess = lane.curvature - _curvatureThreshold;
      // Each 0.01 m⁻¹ of excess curvature adds 5% to required stopping dist.
      final penalty = 1.0 + (excess / 0.01) * 0.05;
      stopDist *= penalty.clamp(1.0, 2.5);
    }

    // 3. Obstacle distance from proximity
    final obstacleDist = _proximityToDistance(obstacle.proximity);

    // 4. Time to impact (closing at current speed, ignoring obstacle speed)
    final tti = obstacleDist / speedMs;

    // 5. Safety ratio and urgency
    final ratio = obstacleDist / stopDist;
    final urgency = _urgencyFromRatio(ratio);

    return BrakingState(
      urgency:            urgency,
      stoppingDistanceM:  stopDist,
      timeToImpactS:      tti,
      obstacleDistanceM:  obstacleDist,
      safetyRatio:        ratio,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Convert normalised proximity [0-1] to an estimated distance in metres
  /// using the pinhole camera model.
  ///
  /// proximity = 1 - (imageY / imageHeight)   (from ObstacleEngine)
  /// → imageY  = (1 - proximity) * imageHeight
  ///
  /// IPM ground distance:
  ///   d = cameraHeight · focalY / dy
  /// where:
  ///   dy = (imageY - principalY) · cos(pitch) - focalY · sin(pitch)
  double _proximityToDistance(double proximity) {
    // Reconstruct approximate image y from proximity
    const double imageHeight = 640.0;
    final imageY = (1.0 - proximity.clamp(0.0, 0.99)) * imageHeight;

    final pitch = _calibration.pitch;
    final dy = (imageY - _calibration.principalY) * math.cos(pitch)
             - _calibration.focalY * math.sin(pitch);

    if (dy <= 0) return 100.0; // above horizon → very far

    final distance = _calibration.cameraHeight * _calibration.focalY / dy;

    // Clamp to reasonable range [1m, 150m]
    return distance.clamp(1.0, 150.0);
  }

  BrakingUrgency _urgencyFromRatio(double ratio) {
    if (ratio > 2.0) return BrakingUrgency.safe;
    if (ratio > 1.2) return BrakingUrgency.caution;
    if (ratio > 0.8) return BrakingUrgency.warning;
    return BrakingUrgency.critical;
  }
}