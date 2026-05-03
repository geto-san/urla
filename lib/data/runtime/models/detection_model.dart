import '../../domain/models/geometry/point.dart';

/// Generic object detection result produced by the AI model.
class DetectionModel {

  final int classId;
  final String className;
  final double confidence;

  final List<Point> mask;

  final double xMin;
  final double yMin;
  final double xMax;
  final double yMax;

  final Map<String, dynamic>? metadata;

  const DetectionModel({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.mask,
    required this.xMin,
    required this.yMin,
    required this.xMax,
    required this.yMax,
    this.metadata,
  });

  double get width => xMax - xMin;
  double get height => yMax - yMin;
}