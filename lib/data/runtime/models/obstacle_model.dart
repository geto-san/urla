/// Represents the obstacle detection state produced by the
/// object detection system.
///
/// This state summarizes the perception output and is used by:
///
/// • Overtake engine
/// • Risk estimation
/// • Driver warnings
///
/// It is recomputed for every processed frame.
class ObstacleState {

  /// True if an obstacle is detected ahead.
  final bool obstacleAhead;

  /// Confidence of the obstacle detection.
  /// Range: 0.0 – 1.0
  final double confidence;

  /// Estimated proximity of the obstacle.
  ///
  /// 0.0 → far away  
  /// 1.0 → very close
  final double proximity;

  const ObstacleState({
    required this.obstacleAhead,
    required this.confidence,
    required this.proximity,
  });

  /// Returns a safe state with no detected obstacles.
  factory ObstacleState.none() {
    return const ObstacleState(
      obstacleAhead: false,
      confidence: 0,
      proximity: 0,
    );
  }
}