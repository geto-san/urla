import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/repositories/road_repository.dart';
import '../../data/domain/enums.dart';

class RiskEngine {
  final RoadRepository _roadRepository;

  RiskEngine(this._roadRepository);

  Future<RoadRiskLevel> evaluate(LaneModel lane, String roadId) async {
    int riskScore = 0;

    // Lane confidence
    if (lane.confidence < 0.4) riskScore += 2;
    if (lane.confidence < 0.2) riskScore += 3;

    // Lane width (metres): narrow roads are riskier
    if (lane.laneWidth < 2.8) riskScore += 2;   // typical narrow road
    if (lane.laneWidth < 2.3) riskScore += 3;   // extremely narrow

    // Drift instability (variance in lateral position, m²)
    if (lane.driftScore > 0.5) riskScore += 1;   // moderate weaving
    if (lane.driftScore > 1.2) riskScore += 3;

    // Curvature (1/m): sharp curves
    if (lane.curvature > 0.05) riskScore += 1;
    if (lane.curvature > 0.1) riskScore += 2;

    // Historical road behaviour
    final historicalRisk = await _roadRepository.getHistoricalRisk(roadId);
    riskScore += historicalRisk;

    // Convert to level
    if (riskScore >= 7) return RoadRiskLevel.critical;
    if (riskScore >= 5) return RoadRiskLevel.high;
    if (riskScore >= 3) return RoadRiskLevel.medium;
    return RoadRiskLevel.low;
  }
}