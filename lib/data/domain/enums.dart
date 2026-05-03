/// Lane marking classification produced by the lane detection model.
enum LaneType {
  solid,
  broken,
  inferred,
  virtual
}

/// Road classification learned from historical driving data.
enum RoadType {
  highway,
  urban,
  rural
}

/// Overall road safety level inferred from accumulated observations.
enum RoadRiskLevel {
  low,
  medium,
  high,
  critical
}

/// Decision output of the overtaking logic.
enum OvertakeDecision {
  allowed,
  notAllowed,
  caution,
  unknown
}