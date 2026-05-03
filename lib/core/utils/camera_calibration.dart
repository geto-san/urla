import 'dart:math' as math;

import 'package:urla/data/domain/models/geometry/point.dart';

/// Holds camera intrinsics and dynamically estimates pitch from lane observations.
///
/// Coordinates:
/// - Image: (u,v) with origin top‑left.
/// - Camera: z forward, x right, y down.
/// - World: X forward, Y left, Z up. Camera mounted at (0,0,H).
class DynamicCalibration {
  final double focalX;  // px
  final double focalY;
  final double principalX;
  final double principalY;
  final double cameraHeight; // metres

  // Estimated pitch angle (radians). Positive = looking up, negative = looking down.
  double _pitch = 0.0;

  // Smoothed vanishing point y‑coordinate (v0)
  double _vanishingY = 0.0;
  bool _initialised = false;

  DynamicCalibration({
    required this.focalX,
    required this.focalY,
    required this.principalX,
    required this.principalY,
    required this.cameraHeight,
  });

  /// Update the calibration using current lane observation.
  /// [vanishingPointY] is the image y‑coordinate where the lane lines converge.
  /// For a true vanishing point, you can use the intersection of detected lane boundaries.
  void updateFromLane(double vanishingPointY) {
    
    if (!_initialised) {
      _vanishingY = vanishingPointY;
      _initialised = true;
    } else {
      // Exponential smoothing
      const alpha = 0.2;
      _vanishingY = alpha * vanishingPointY + (1 - alpha) * _vanishingY;
    }

    // Estimate pitch from vanishing point:
    // In a pinhole camera with no roll, vanishing point v = principalY - focalY * tan(pitch)
    //   => pitch = atan2(principalY - v, focalY)
    _pitch = math.atan2(principalY - _vanishingY, focalY);
  }

  /// Convert image point (u,v) to world ground coordinates (forward, left) in metres.
  /// Returns null if the point is above the dynamic horizon (v <= vanishing_y).
  ({double forward, double left})? imageToWorld(double u, double v) {

    // v must be below the vanishing point (i.e., ground)
    if (v <= _vanishingY) return null;
    
    // Camera coordinates: rotate by pitch (simple model: camera tilted, ground plane Z=0)
    // For small angles, we can use the classic IPM with pitch:
    //   dy = (v - principalY) * cos(pitch) - focalY * sin(pitch)
    //   dz = (v - principalY) * sin(pitch) + focalY * cos(pitch)
    // Ground intersection at Y_world = H (camera height above road), so we find t such that
    // Y_cam = H. This derivation is lengthy; we'll use a simplified robust formula:
    //   forward = H * focalY / ( (v - principalY) * cos(pitch) - focalY * sin(pitch) )
    //   left   = (u - principalX) * forward / focalX
    // This assumes roll = 0 and principal point at centre.
    final double dy = (v - principalY) * math.cos(_pitch) - focalY * math.sin(_pitch);
    if (dy == 0) return null;

    final double forward = cameraHeight * focalY / dy;
    final double left = (u - principalX) * forward / focalX;
    return (forward: forward, left: left);
  }

  /// Convert a list of image points to world list.
  List<({double forward, double left})> pointsToWorld(List<Point> imagePoints) {
    return imagePoints
        .map((p) => imageToWorld(p.x, p.y))
        .where((w) => w != null)
        .cast<({double forward, double left})>()
        .toList();
  }

  /// Returns the current estimated pitch in radians.
  double get pitch => _pitch;
  double get vanishingY => _vanishingY;
}