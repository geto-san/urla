import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// HapticService
//
// Provides structured vibration feedback mapped to urgency levels.
// Falls back to Flutter's HapticFeedback when the vibration package
// reports the device has no vibrator.
//
// Patterns (duration in ms, amplitude 0-255):
//   light   : single 80ms  pulse  – informational
//   medium  : double 150ms pulses – caution
//   strong  : triple 200ms pulses – warning
//   critical: long   500ms pulse  – emergency
// ---------------------------------------------------------------------------
class HapticService {
  bool _hasVibrator = false;

  /// Minimum gap between same-pattern vibrations.
  static const Duration _cooldown = Duration(milliseconds: 800);
  DateTime? _lastVibration;

  Future<void> initialize() async {
    try {
      _hasVibrator = await Vibration.hasVibrator() ?? false;
    } catch (e) {
      debugPrint('HapticService: vibration check failed – $e');
      _hasVibrator = false;
    }
  }

  // ── Public patterns ────────────────────────────────────────────────────────

  /// Single soft pulse — low-priority information.
  Future<void> light() => _trigger(
    durations: [80],
    amplitudes: [80],
  );

  /// Two medium pulses — caution level.
  Future<void> medium() => _trigger(
    durations: [150, 100, 150],
    amplitudes: [150, 0, 150],
  );

  /// Three strong pulses — warning.
  Future<void> strong() => _trigger(
    durations: [200, 80, 200, 80, 200],
    amplitudes: [200, 0, 200, 0, 200],
  );

  /// Sustained strong pulse — critical / emergency.
  Future<void> critical() => _trigger(
    durations: [500],
    amplitudes: [255],
    overrideCooldown: true,   // always fire critical regardless of cooldown
  );

  // ── Private ────────────────────────────────────────────────────────────────

  Future<void> _trigger({
    required List<int> durations,
    required List<int> amplitudes,
    bool overrideCooldown = false,
  }) async {
    final now = DateTime.now();
    if (!overrideCooldown &&
        _lastVibration != null &&
        now.difference(_lastVibration!) < _cooldown) {
      return;
    }
    _lastVibration = now;

    try {
      if (_hasVibrator) {
        // vibration package: pattern = [delay, vibrate, pause, vibrate ...]
        await Vibration.vibrate(
          pattern:    durations,
          intensities: amplitudes,
        );
      } else {
        // Fallback: map to Flutter's built-in haptic
        final totalMs = durations.reduce((a, b) => a + b);
        if (totalMs < 150) {
          await HapticFeedback.lightImpact();
        } else if (totalMs < 400) {
          await HapticFeedback.mediumImpact();
        } else {
          await HapticFeedback.heavyImpact();
        }
      }
    } catch (e) {
      debugPrint('HapticService error: $e');
    }
  }
}