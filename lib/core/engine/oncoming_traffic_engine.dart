import '../../data/runtime/models/detection_model.dart';
import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/models/geometry/point.dart';
import '../../data/runtime/models/oncomimg_model.dart';
import '../../core/utils/camera_calibration.dart';

class OncomingTrafficEngine {
  final DynamicCalibration calibration;

  OncomingTrafficEngine(this.calibration);

  OncomingTrafficState evaluate(List<DetectionModel> detections, LaneModel lane) {
    // Filter vehicles only
    final vehicles = detections.where((d) => d.className == 'road_obstruction').toList();
    if (vehicles.isEmpty) return OncomingTrafficState.safe();

    // Get ego lane's right boundary in world coords for oncoming check (Uganda: left‑hand traffic)
    final worldRightBoundary = calibration.pointsToWorld(lane.rightBoundary);
    if (worldRightBoundary.isEmpty) return OncomingTrafficState.safe();

    // Average right boundary lateral position at ego vehicle's depth (forward ~5-20m)
    final avgRightLateral = worldRightBoundary
        .where((p) => p.forward > 5 && p.forward < 30)
        .map((p) => p.left)
        .fold(0.0, (a, b) => a + b) /
        (worldRightBoundary.where((p) => p.forward > 5 && p.forward < 30).isEmpty
            ? 1
            : worldRightBoundary.where((p) => p.forward > 5 && p.forward < 30).length);

    int oncomingCount = 0;
    double totalRisk = 0;

    for (final vehicle in vehicles) {
      final centroid = _centroid(vehicle.mask);
      final worldPoint = calibration.imageToWorld(centroid.x, centroid.y);
      if (worldPoint == null) continue;

      // Oncoming lane: lateral position to the right of ego lane (left‑hand traffic)
      if (worldPoint.left > avgRightLateral + 1.0) { // 1m buffer
        oncomingCount++;
        // Risk: higher if close (low forward distance) and more lateral offset
        final distance = worldPoint.forward;
        final proximityRisk = (20.0 / (distance + 1.0)).clamp(0.0, 1.0);
        totalRisk += proximityRisk * vehicle.confidence;
      }
    }

    if (oncomingCount == 0) return OncomingTrafficState.safe();

    final density = (oncomingCount / 5.0).clamp(0.0, 1.0); // max 5 vehicles visible
    final avgRisk = totalRisk / oncomingCount;

    return OncomingTrafficState(
      vehicleDetectedAhead: true,
      densityScore: density,
      riskScore: avgRisk.clamp(0.0, 1.0),
    );
  }

  Point _centroid(List<Point> mask) {
    if (mask.isEmpty) return const Point(0, 0);   // guard added
    double x = 0, y = 0;
    for (final p in mask) { x += p.x; y += p.y; }
    return Point(x / mask.length, y / mask.length);
  }
}