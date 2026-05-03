import 'package:flutter/material.dart';
import 'package:urla/data/domain/models/geometry/point.dart';
import '../../../data/runtime/models/frame_processing_result.dart';
import '../../../data/runtime/models/detection_model.dart';

class LaneOverlayPainter extends CustomPainter {
  static const double modelInputSize = 640.0;   // must match PreprocessService.inputSize
  final FrameProcessingResult? result;

  LaneOverlayPainter(this.result);

  @override
  void paint(Canvas canvas, Size size) {
    if (result == null) return;

    final lane = result!.lane;
    final detections = result!.detections;

    // Scale factors to convert model coordinates → canvas pixels
    final scaleX = size.width / modelInputSize;
    final scaleY = size.height / modelInputSize;

    if (lane != null && lane.centerLine.isNotEmpty) {
      _drawLanePolyline(canvas, lane.centerLine, Colors.green, 3.0, scaleX, scaleY);
      _drawLanePolyline(canvas, lane.leftBoundary, Colors.yellow, 2.0, scaleX, scaleY);
      _drawLanePolyline(canvas, lane.rightBoundary, Colors.yellow, 2.0, scaleX, scaleY);
    }

    for (final det in detections) {
      _drawDetectionBox(canvas, det, size, scaleX, scaleY);
    }

    if (lane != null && lane.confidence < 0.5) {
      _drawWarning(canvas, size, 'Low Lane Confidence');
    }
  }

  void _drawLanePolyline(Canvas canvas, List<Point> points, Color color,
      double strokeWidth, double scaleX, double scaleY) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].x * scaleX, points[0].y * scaleY);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].x * scaleX, points[i].y * scaleY);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDetectionBox(Canvas canvas, DetectionModel det, Size size,
      double scaleX, double scaleY) {
    final paint = Paint()
      ..color = det.className == 'vehicle' ? Colors.red : Colors.blue
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTRB(
      det.xMin * scaleX,
      det.yMin * scaleY,
      det.xMax * scaleX,
      det.yMax * scaleY,
    );
    canvas.drawRect(rect, paint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${det.className} ${(det.confidence * 100).toStringAsFixed(0)}%',
        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(det.xMin * scaleX, det.yMin * scaleY - 15));
  }

  void _drawWarning(Canvas canvas, Size size, String message) {
    final paint = Paint()..color = Colors.red.withOpacity(0.2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 40), paint);
    final textPainter = TextPainter(
      text: TextSpan(text: message, style: TextStyle(color: Colors.white, fontSize: 18)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(10, 8));
  }

  @override
  bool shouldRepaint(LaneOverlayPainter old) => old.result != result;
}