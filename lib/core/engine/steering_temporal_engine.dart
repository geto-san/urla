import 'dart:math';
import 'package:urla/data/runtime/models/detection_model.dart';

import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/enums.dart';
import 'steering_engine.dart';

class TemporalSteeringEngine {

  final SteeringIntentEngine _steeringEngine;

  TemporalSteeringEngine(this._steeringEngine);

  LaneModel? _previousLane;
  OvertakeDecision? _previousDecision;

  final List<double> _confidenceHistory = [];
  final List<double> _driftHistory = [];
  final List<bool> _obstacleHistory = [];
  final List<bool> _oncomingHistory = [];

  double _smoothedConfidence = 0;
  double _smoothedDrift = 0;

  final double alpha = 0.7;

  /// hysteresis counter
  int _safeFrameCounter = 0;

  /// main entry
  OvertakeDecision evaluate(
  LaneModel lane,
  List<DetectionModel> detections,  // 🆕
  bool obstacleAhead,
  bool oncomingRisk,
) {
  _updateHistory(lane, obstacleAhead, oncomingRisk);
  final rawDecision = _steeringEngine.evaluateOvertake(lane, detections); 

    final smoothed = _smoothDecision(rawDecision, lane);

    _previousLane = lane;
    _previousDecision = smoothed;

    return smoothed;
  }

  // -------------------------------------------------
  // HISTORY UPDATE
  // -------------------------------------------------
  void _updateHistory(
    LaneModel lane,
    bool obstacleAhead,
    bool oncomingRisk,
  ) {

    _confidenceHistory.add(lane.confidence);
    _driftHistory.add(lane.driftScore);

    _obstacleHistory.add(obstacleAhead);
    _oncomingHistory.add(oncomingRisk);

    if (_confidenceHistory.length > 10) {
      _confidenceHistory.removeAt(0);
      _driftHistory.removeAt(0);
      _obstacleHistory.removeAt(0);
      _oncomingHistory.removeAt(0);
    }

    //exponetial smoothing
    _smoothedConfidence =
        alpha * _smoothedConfidence + (1 - alpha) * lane.confidence;

    _smoothedDrift =
        alpha * _smoothedDrift + (1 - alpha) * lane.driftScore;
  }

  // -------------------------------------------------
  // DECISION SMOOTHING
  // -------------------------------------------------
  OvertakeDecision _smoothDecision(
    OvertakeDecision current,
    LaneModel lane,
  ) {

    /// 1. unstable environment
    if (_isUnstableEnvironment()) {
      return OvertakeDecision.caution;
    }

    /// 2. lane jump
    if (_laneJumpDetected(lane)) {
      return OvertakeDecision.notAllowed;
    }

    /// 3. NEW: persistent obstacle safety
    if (_obstaclePersistent()) {
      return OvertakeDecision.notAllowed;
    }

    /// 4. NEW: oncoming traffic persistence
    if (_oncomingPersistent()) {
      return OvertakeDecision.caution;
    }

    /// 5. hysteresis logic (unchanged but safer)
    if (_previousDecision == OvertakeDecision.notAllowed) {

      if (current == OvertakeDecision.allowed) {
        _safeFrameCounter++;

        if (_safeFrameCounter < 3) {
          return OvertakeDecision.caution;
        }
      } else {
        _safeFrameCounter = 0;
        return OvertakeDecision.notAllowed;
      }
    }

    return current;
  }
    
  // -------------------------------------------------
  // ENVIRONMENT STABILITY
  // -------------------------------------------------
  bool _isUnstableEnvironment() {

    if (_confidenceHistory.length < 3) return true;

    final variance = _variance(_confidenceHistory);

    if (variance > 0.05) return true;

    if (_smoothedConfidence < 0.4) return true;

    return false;
  }

  // -------------------------------------------------
  // LANE JUMP DETECTION
  // -------------------------------------------------
  bool _laneJumpDetected(LaneModel lane) {

    if (_previousLane == null) return false;

    final prev = _previousLane!;
    final curr = lane;

    if (prev.centerLine.isEmpty || curr.centerLine.isEmpty) {
      return true;
    }

    // Use the LAST point (closest to camera, highest Y)
    final p = prev.centerLine.last;
    final c = curr.centerLine.last;

    final dx = (p.x - c.x).abs();
    final dy = (p.y - c.y).abs();

    return (dx + dy) > 40; // pixel jump threshold
  }

  // -------------------------------------------------
  // VARIANCE
  // -------------------------------------------------
  double _variance(List<double> values) {

    final mean = values.reduce((a, b) => a + b) / values.length;

    return values
        .map((v) => pow(v - mean, 2))
        .reduce((a, b) => a + b) /
        values.length;
  }

  // -------------------------------------------------
  // SAFTY PERSISTENCE CHECK
  // -------------------------------------------------
  bool _obstaclePersistent() {
    if (_obstacleHistory.length < 3) return false;

    final recent = _obstacleHistory.sublist(_obstacleHistory.length - 3);

    return recent.every((e) => e == true);
  }

  bool _oncomingPersistent() {
    if (_oncomingHistory.length < 3) return false;

    final recent = _oncomingHistory.sublist(_oncomingHistory.length - 3);

    return recent.any((e) => e == true);
  }

}