import 'obstacle_model.dart';
import 'oncomimg_model.dart';
import 'lane_model.dart';
import 'detection_model.dart';
import '../../domain/enums.dart';
import '../../../core/engine/braking_horizon_engine.dart';

/// The complete output of one perception cycle.
/// Carried from [FrameProcessor] → [CameraViewModel] → UI overlay + OutputCoordinator.
class FrameProcessingResult {
  /// Smoothed lane geometry (Kalman-filtered). Null if no lane was detected
  /// and virtual generation also failed.
  final LaneModel? lane;

  /// All detections from the current frame.
  final List<DetectionModel> detections;

  /// Obstacle state from [ObstacleEngine].
  final ObstacleState? obstacle;

  /// Oncoming traffic state from [OncomingTrafficEngine].
  final OncomingTrafficState? traffic;

  /// Final overtake decision (temporally smoothed).
  final OvertakeDecision? overtakeDecision;

  /// Braking urgency from [BrakingHorizonEngine].
  final BrakingState? brakingState;

  /// Original frame dimensions (pixels) that were fed into the ML model.
  /// The overlay painter uses these to map model-space coordinates back to
  /// the correct position on screen regardless of display resolution.
  final int frameWidth;
  final int frameHeight;

  /// True when the lane is virtual (synthesised, not detected).
  bool get isVirtualLane => lane?.type.name == 'virtual';

  const FrameProcessingResult({
    this.lane,
    this.detections = const [],
    this.obstacle,
    this.traffic,
    this.overtakeDecision,
    this.brakingState,
    this.frameWidth  = 640,
    this.frameHeight = 640,
  });
}