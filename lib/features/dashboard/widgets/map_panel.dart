import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/runtime/models/geo_data.dart';

class MapPanel extends StatelessWidget {
  final ValueNotifier<GeoData?> geoNotifier;
  const MapPanel({super.key, required this.geoNotifier});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GeoData?>(
      valueListenable: geoNotifier,
      builder: (context, geo, _) {
        if (geo == null) {
          return const Center(child: Text("Waiting for GPS...",
              style: TextStyle(color: Colors.white54)));
        }
        try {
          final pos = LatLng(geo.latitude, geo.longitude);
          return FlutterMap(
            options: MapOptions(initialCenter: pos, initialZoom: 16),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.urla',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pos,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.navigation,
                        color: Colors.blueAccent, size: 30),
                  ),
                ],
              ),
            ],
          );
        } catch (e) {
          return Center(
            child: Text(
              "Map unavailable\n(${e.toString().split('\n').first})",
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          );
        }
      },
    );
  }
}