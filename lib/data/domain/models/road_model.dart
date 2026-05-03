import '../enums.dart';

/// Represents learned behaviour of a road segment.
///
/// Each road segment aggregates historical observations collected
/// while driving through the same geographic region.
class RoadModel {

  final String id;

  final double lat;
  final double lng;

  final double avgLaneWidth;
  final double avgCurvature;
  final double avgDrift;

  final RoadType roadType;

  final int sampleCount;

  const RoadModel({
    required this.id,
    required this.lat,
    required this.lng,
    required this.avgLaneWidth,
    required this.avgCurvature,
    required this.avgDrift,
    required this.roadType,
    required this.sampleCount,
  });
}