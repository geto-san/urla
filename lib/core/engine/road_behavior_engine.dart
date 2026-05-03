import '../../data/domain/models/road_model.dart';
import '../../data/domain/enums.dart';

// ---------------------------------------------------------------------------
// RoadBias
//
// The output of [RoadBehaviourEngine]. Consumed by [SteeringIntentEngine]
// and [FrameProcessor] to adjust thresholds before per-frame decisions.
// ---------------------------------------------------------------------------
class RoadBias {
  /// If non-null, this overrides the live overtake decision entirely.
  /// Used when historical data strongly indicates unsafe conditions.
  final OvertakeDecision? overtakeOverride;

  /// Extra risk points to add to the live score (from [RiskEngine]).
  /// Range: 0–5.
  final int riskBump;

  /// Tolerated drift above the normal threshold (metres).
  /// If this road is known to be wavy, we relax the drift alarm.
  final double driftTolerance;

  /// True when the historical data is based on enough samples to be trusted.
  final bool isReliable;

  /// The road model that produced this bias (may be null for unknown roads).
  final RoadModel? source;

  const RoadBias({
    this.overtakeOverride,
    this.riskBump           = 0,
    this.driftTolerance     = 0.0,
    this.isReliable         = false,
    this.source,
  });

  /// Default bias — no historical influence.
  factory RoadBias.neutral() => const RoadBias();

  bool get hasOverride => overtakeOverride != null;
}

// ---------------------------------------------------------------------------
// RoadBehaviourEngine
//
// Reads a [RoadModel] (already fetched from the DB by the caller) and
// produces a [RoadBias] that biases downstream decisions.
//
// Decision tree (evaluated in order, first match wins):
//
//   1. sampleCount < [_minSamples]
//      → RoadBias.neutral()   (not enough data to trust)
//
//   2. avgLaneWidth < 2.3m AND sampleCount > [_reliableCount]
//      → overtakeOverride = notAllowed   (road is historically very narrow)
//
//   3. avgDrift > 0.6m AND sampleCount > [_reliableCount]
//      → driftTolerance += 0.2m          (road is normally wavy — relax alarm)
//        overtakeOverride = caution
//
//   4. avgCurvature > 0.08 m⁻¹
//      → overtakeOverride = caution      (historically winding)
//        riskBump += 1
//
//   5. avgLaneWidth < 2.8m
//      → riskBump += 1                   (narrower than typical road)
//
//   6. sampleCount > 50 AND avgDrift > 0.5m
//      → riskBump += 2                   (persistently unstable lane
//
// Multiple rules can apply; overrides take the most restrictive value.
// ---------------------------------------------------------------------------
class RoadBehaviourEngine {
  /// Minimum observations before we trust historical data.
  static const int _minSamples = 5;

  /// Sample count at which data is considered fully reliable.
  static const int _reliableCount = 20;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Produce a [RoadBias] from a [RoadModel].
  ///
  /// Pass [road] = null when no segment is found in the DB
  /// (first time on this road → neutral bias).
  RoadBias evaluate(RoadModel? road) {
    if (road == null) return RoadBias.neutral();
    if (road.sampleCount < _minSamples) return RoadBias.neutral();

    final isReliable = road.sampleCount >= _reliableCount;

    OvertakeDecision? overtakeOverride;
    int riskBump = 0;
    double driftTolerance = 0.0;

    // ── Rule 1: historically very narrow road ─────────────────────────────
    if (road.avgLaneWidth < 2.3 && isReliable) {
      overtakeOverride = _worstOverride(
        overtakeOverride,
        OvertakeDecision.notAllowed,
      );
      riskBump += 2;
    }

    // ── Rule 2: historically wavy / high drift ────────────────────────────
    if (road.avgDrift > 0.6 && isReliable) {
      // Relax the drift alarm because the road is normally like this.
      driftTolerance += 0.20;
      overtakeOverride = _worstOverride(
        overtakeOverride,
        OvertakeDecision.caution,
      );
    }

    // ── Rule 3: historically winding ─────────────────────────────────────
    if (road.avgCurvature > 0.08) {
      overtakeOverride = _worstOverride(
        overtakeOverride,
        OvertakeDecision.caution,
      );
      riskBump += 1;
    }

    // ── Rule 4: moderately narrow road ───────────────────────────────────
    if (road.avgLaneWidth < 2.8 && road.avgLaneWidth >= 2.3) {
      riskBump += 1;
    }

    // ── Rule 5: persistently unstable (many samples, still drifty) ───────
    if (road.sampleCount > 50 && road.avgDrift > 0.5) {
      riskBump += 2;
    }

    return RoadBias(
      overtakeOverride: overtakeOverride,
      riskBump:         riskBump.clamp(0, 5),
      driftTolerance:   driftTolerance,
      isReliable:       isReliable,
      source:           road,
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  /// Returns the more restrictive of two [OvertakeDecision] values.
  /// Restrictiveness order: notAllowed > caution > allowed > unknown.
  OvertakeDecision _worstOverride(
    OvertakeDecision? current,
    OvertakeDecision candidate,
  ) {
    if (current == null) return candidate;
    return _severity(candidate) > _severity(current) ? candidate : current;
  }

  int _severity(OvertakeDecision d) {
    switch (d) {
      case OvertakeDecision.notAllowed: return 3;
      case OvertakeDecision.caution:    return 2;
      case OvertakeDecision.allowed:    return 1;
      case OvertakeDecision.unknown:    return 0;
    }
  }
}