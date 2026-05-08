import 'package:flutter/material.dart';
import 'package:urla/core/engine/braking_horizon_engine.dart';
import 'package:urla/data/domain/enums.dart';
import '../../../data/runtime/models/frame_processing_result.dart';

class DebugPanel extends StatelessWidget {
  final ValueNotifier<FrameProcessingResult?> overlayNotifier;
  final bool debugMode;

  const DebugPanel({super.key, required this.overlayNotifier, required this.debugMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      padding: EdgeInsets.all(8),
      child: ValueListenableBuilder<FrameProcessingResult?>(
        valueListenable: overlayNotifier,
        builder: (context, result, _) {
          if (result == null) return Center(child: Text("Waiting for first frame...", style: TextStyle(color: Colors.white54)));
          final lane = result.lane;
          final detections = result.detections;
          final obstacle = result.obstacle;
          final traffic = result.traffic;
          final overtake = result.overtakeDecision;
          final braking = result.brakingState;

          return SingleChildScrollView(
            child: DefaultTextStyle(
              style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("━━━ Pipeline Output ━━━", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 6),
                  if (lane != null) ...[
                    Text("Lane: ${result.isVirtualLane ? 'VIRTUAL' : 'DETECTED'}"),
                    Text("  Confidence: ${lane.confidence.toStringAsFixed(2)}"),
                    Text("  Width: ${lane.laneWidth.toStringAsFixed(2)} m  Drift: ${lane.driftScore.toStringAsFixed(2)} m  Curv: ${lane.curvature.toStringAsFixed(3)}"),
                    SizedBox(height: 4),
                  ],
                  Text("Detections (${detections.length}):"),
                  for (var det in detections.take(6))
                    Text("  ${det.className}: ${(det.confidence*100).toStringAsFixed(0)}%"),
                  if (detections.length > 6) Text("  ... and ${detections.length-6} more"),
                  SizedBox(height: 6),
                  if (obstacle != null)
                    Text("Obstacle: ${obstacle.obstacleAhead ? 'YES' : 'no'}  proximity ${obstacle.proximity.toStringAsFixed(2)}"),
                  if (traffic != null)
                    Text("Oncoming: ${traffic.vehicleDetectedAhead ? 'YES' : 'no'}  risk ${traffic.riskScore.toStringAsFixed(2)}"),
                  if (overtake != null)
                    Text("Overtake: ${overtake.name}", style: TextStyle(color: _overtakeColor(overtake))),
                  if (braking != null)
                    Text("Braking: ${braking.urgency.name} (ratio ${braking.safetyRatio.toStringAsFixed(1)})", style: TextStyle(color: _brakingColor(braking.urgency))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _overtakeColor(OvertakeDecision d) {
    switch (d) {
      case OvertakeDecision.allowed: return Colors.green;
      case OvertakeDecision.caution: return Colors.orange;
      case OvertakeDecision.notAllowed: return Colors.red;
      case OvertakeDecision.unknown: return Colors.grey;
    }
  }
  Color _brakingColor(BrakingUrgency u) {
    switch (u) {
      case BrakingUrgency.safe: return Colors.green;
      case BrakingUrgency.caution: return Colors.orange;
      case BrakingUrgency.warning: return Colors.deepOrange;
      case BrakingUrgency.critical: return Colors.red;
    }
  }
}