import 'dart:async';   // add if not present
import 'package:geolocator/geolocator.dart';
import 'package:urla/data/runtime/models/geo_data.dart';

class GeoService {
  Position? _lastPosition;

  Future<GeoData> getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 2),
        ),
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          if (_lastPosition != null) return _lastPosition!;
          throw TimeoutException('Location timeout', const Duration(seconds: 3));
        },
      );

      _lastPosition = position;
      return GeoData(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
        timestamp: DateTime.now(),
      );
      
    } catch (e) {
      if (_lastPosition != null) {
        return GeoData(
          latitude: _lastPosition!.latitude,
          longitude: _lastPosition!.longitude,
          speed: _lastPosition!.speed,
          heading: _lastPosition!.heading,
          timestamp: DateTime.now(),
        );
      }
      rethrow;
    }
  }
}