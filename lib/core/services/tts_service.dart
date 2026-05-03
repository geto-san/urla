import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// TtsService
//
// Wraps flutter_tts with:
//   • Per-message-type rate limiting (prevents flooding the driver)
//   • Priority queue (critical messages interrupt lower-priority ones)
//   • Language / speed tuned for in-vehicle use
//
// Priorities (higher = spoken first / interrupts lower):
//   4 = critical braking
//   3 = obstacle / oncoming
//   2 = overtake decision
//   1 = lane confidence warning
//   0 = informational
// ---------------------------------------------------------------------------

enum TtsPriority { info, laneWarning, overtake, hazard, critical }

class TtsService {
  final FlutterTts _tts = FlutterTts();

  bool _isSpeaking = false;

  /// Tracks the last time each message was spoken.
  final Map<String, DateTime> _lastSpoken = {};

  /// Minimum gap between repeating the same message type.
  static const Map<TtsPriority, Duration> _cooldowns = {
    TtsPriority.critical:     Duration(seconds: 2),
    TtsPriority.hazard:       Duration(seconds: 3),
    TtsPriority.overtake:     Duration(seconds: 4),
    TtsPriority.laneWarning:  Duration(seconds: 5),
    TtsPriority.info:         Duration(seconds: 6),
  };

  Future<void> initialize() async {
    await _tts.setLanguage('en-UG');           // Ugandan English locale
    await _tts.setSpeechRate(0.50);            // slightly slower for clarity
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      debugPrint('TTS error: $msg');
    });
  }

  /// Speak [message] if the cooldown for [priority] / [key] has elapsed.
  ///
  /// [key] groups messages for rate-limiting. Use a specific key like
  /// 'braking_critical' so different types don't share cooldowns.
  ///
  /// [interrupt] = true will stop the current utterance immediately.
  Future<void> speak(
    String message, {
    required TtsPriority priority,
    required String key,
    bool interrupt = false,
  }) async {
    final cooldown = _cooldowns[priority] ?? const Duration(seconds: 4);
    final last = _lastSpoken[key];

    if (last != null && DateTime.now().difference(last) < cooldown) {
      return; // still in cooldown — skip
    }

    if (_isSpeaking) {
      if (!interrupt) return;
      await _tts.stop();
    }

    _lastSpoken[key] = DateTime.now();

    try {
      await _tts.speak(message);
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
  }

  Future<void> dispose() async {
    await stop();
  }
}