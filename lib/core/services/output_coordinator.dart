import '../../data/runtime/models/frame_processing_result.dart';
import '../../data/domain/enums.dart';
import 'tts_service.dart';
import 'haptic_service.dart';
import '../engine/braking_horizon_engine.dart';

// ---------------------------------------------------------------------------
// OutputCoordinator
//
// Single entry point that reads [FrameProcessingResult] and decides what
// to say / vibrate. Keeps TTS and haptic services completely decoupled from
// the perception pipeline.
//
// Priority rules (highest first):
//   1. Critical braking  → TTS + strong haptic   (always interrupts)
//   2. Warning braking   → TTS + medium haptic
//   3. Obstacle ahead    → TTS + medium haptic
//   4. Do not overtake   → TTS + light haptic
//   5. Caution overtake  → TTS only
//   6. Oncoming traffic  → TTS + light haptic
//   7. Low lane conf.    → TTS only
// ---------------------------------------------------------------------------
class OutputCoordinator {
  final TtsService _tts;
  final HapticService _haptic;

  OutputCoordinator(this._tts, this._haptic);

  /// Call once per processed frame result.
  Future<void> process(FrameProcessingResult result) async {
    // Run TTS and haptic concurrently to avoid blocking each other.
    await Future.wait([
      _processTts(result),
      _processHaptic(result),
    ]);
  }

  // ── TTS ────────────────────────────────────────────────────────────────────

  Future<void> _processTts(FrameProcessingResult result) async {
    final braking  = result.brakingState;
    final obstacle = result.obstacle;
    final traffic  = result.traffic;
    final lane     = result.lane;
    final overtake = result.overtakeDecision;

    // 1. Critical braking — highest priority, interrupts everything
    if (braking != null && braking.urgency == BrakingUrgency.critical) {
      await _tts.speak(
        'Brake now',
        priority:  TtsPriority.critical,
        key:       'braking_critical',
        interrupt: true,
      );
      return; // skip lower-priority messages this frame
    }

    // 2. Braking warning
    if (braking != null && braking.urgency == BrakingUrgency.warning) {
      await _tts.speak(
        'Slow down, obstacle close',
        priority:  TtsPriority.hazard,
        key:       'braking_warning',
        interrupt: false,
      );
      return;
    }

    // 3. Obstacle ahead (proximity threshold)
    if (obstacle != null &&
        obstacle.obstacleAhead &&
        obstacle.proximity > 0.65) {
      await _tts.speak(
        'Obstacle ahead',
        priority:  TtsPriority.hazard,
        key:       'obstacle_ahead',
        interrupt: false,
      );
      return;
    }

    // 4. Overtake: not allowed
    if (overtake == OvertakeDecision.notAllowed) {
      await _tts.speak(
        'Do not overtake',
        priority:  TtsPriority.overtake,
        key:       'overtake_not_allowed',
        interrupt: false,
      );
      return;
    }

    // 5. Oncoming traffic
    if (traffic != null &&
        traffic.vehicleDetectedAhead &&
        traffic.riskScore > 0.4) {
      await _tts.speak(
        'Oncoming vehicle',
        priority:  TtsPriority.hazard,
        key:       'oncoming_traffic',
        interrupt: false,
      );
      return;
    }

    // 6. Overtake: caution (less frequent)
    if (overtake == OvertakeDecision.caution) {
      await _tts.speak(
        'Overtake with caution',
        priority:  TtsPriority.overtake,
        key:       'overtake_caution',
        interrupt: false,
      );
      return;
    }

    // 7. Low lane confidence
    if (lane != null && lane.confidence < 0.30) {
      await _tts.speak(
        'Lane markings unclear',
        priority:  TtsPriority.laneWarning,
        key:       'lane_confidence_low',
        interrupt: false,
      );
    }
  }

  // ── Haptic ─────────────────────────────────────────────────────────────────

  Future<void> _processHaptic(FrameProcessingResult result) async {
    final braking  = result.brakingState;
    final obstacle = result.obstacle;
    final overtake = result.overtakeDecision;

    if (braking != null) {
      switch (braking.urgency) {
        case BrakingUrgency.critical:
          await _haptic.critical();
          return;
        case BrakingUrgency.warning:
          await _haptic.strong();
          return;
        case BrakingUrgency.caution:
          await _haptic.medium();
          return;
        case BrakingUrgency.safe:
          break;
      }
    }

    if (obstacle != null && obstacle.obstacleAhead) {
      if (obstacle.proximity > 0.8) {
        await _haptic.strong();
        return;
      }
      if (obstacle.proximity > 0.5) {
        await _haptic.medium();
        return;
      }
    }

    if (overtake == OvertakeDecision.notAllowed) {
      await _haptic.light();
    }
  }

  Future<void> dispose() async {
    await _tts.dispose();
  }
}