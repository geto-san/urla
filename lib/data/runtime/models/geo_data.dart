/// Real-time geographic data obtained from device sensors.
///
/// This data is produced by the GPS / location provider
/// and consumed by multiple subsystems:
///
/// • Road learning engine
/// • Geofencing engine
/// • Risk estimation
/// • Driving event logging
///.
class GeoData {

  /// Latitude in WGS84 coordinates
  final double latitude;

  /// Longitude in WGS84 coordinates
  final double longitude;

  /// Speed of the vehicle in meters per second.
  final double speed;

  /// Direction of travel in degrees (0–360).
  /// 0 = North
  /// 90 = East
  final double heading;

  /// Timestamp of the sensor reading.
  final DateTime timestamp;

  const GeoData({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
  });
}