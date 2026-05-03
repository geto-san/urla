import 'package:urla/data/runtime/models/detection_model.dart';

import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/enums.dart';
import 'oncoming_traffic_engine.dart';
import '../../data/runtime/models/oncomimg_model.dart';

class SteeringIntentEngine {

  final OncomingTrafficEngine _oncomingEngine;

  SteeringIntentEngine(this._oncomingEngine);


  OvertakeDecision evaluateOvertake(LaneModel lane, List<DetectionModel> detections) {
    final traffic = _oncomingEngine.evaluate(detections, lane);

    if (lane.centerLine.isEmpty) return _handleMissingCenterLine(lane, traffic);

    // 🆕 Use metric values
    if (lane.driftScore > 1.0) return OvertakeDecision.notAllowed;   // 1.0 m variance
    if (lane.laneWidth < 2.8) return OvertakeDecision.notAllowed;    // 2.8 metres minimum
    if (lane.curvature > 0.08) return OvertakeDecision.caution;     // sharp curve

    if (traffic.vehicleDetectedAhead) {
      if (traffic.riskScore > 0.4) return OvertakeDecision.notAllowed;
      if (traffic.densityScore > 0.2) return OvertakeDecision.caution;
    }

    if (lane.confidence > 0.75 && lane.driftScore < 0.5 && !traffic.vehicleDetectedAhead) {
      return OvertakeDecision.allowed;
    }

    return OvertakeDecision.caution;
  }

  // -----------------------------------
  // Missing center line handling
  // -----------------------------------
  OvertakeDecision _handleMissingCenterLine(
    LaneModel lane,
    OncomingTrafficState traffic,
  ) {

    if (traffic.vehicleDetectedAhead &&
        traffic.riskScore > 0.3) {
      return OvertakeDecision.notAllowed;
    }

    if (lane.confidence < 0.6) {
      return OvertakeDecision.notAllowed;
    }

    if (lane.laneWidth > 3.5 &&
        lane.driftScore < 0.4 &&
        !traffic.vehicleDetectedAhead) {
      return OvertakeDecision.caution;
    }

    return OvertakeDecision.notAllowed;
  }
}