/// Represents the state of oncoming traffic
/// detected from the camera perception system.
///
/// This information is critical for:
///
/// • Overtake decision engine
/// • Collision avoidance
/// • Driver alerts
class OncomingTrafficState {

  /// True if at least one vehicle is detected ahead
  /// in the opposite lane.
  final bool vehicleDetectedAhead;

  /// Estimated density of oncoming traffic.
  ///
  /// 0.0 → empty road  
  /// 1.0 → heavy traffic
  final double densityScore;

  /// Risk score derived from speed, distance and count.
  ///
  /// 0.0 → safe  
  /// 1.0 → extremely dangerous
  final double riskScore;

  const OncomingTrafficState({
    required this.vehicleDetectedAhead,
    required this.densityScore,
    required this.riskScore,
  });

  /// Default safe state when no traffic is detected.
  factory OncomingTrafficState.safe() {
    return const OncomingTrafficState(
      vehicleDetectedAhead: false,
      densityScore: 0,
      riskScore: 0,
    );
  }
}