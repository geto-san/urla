import 'package:flutter/material.dart';
import 'package:urla/data/domain/models/geometry/point.dart';
import '../../../data/runtime/models/frame_processing_result.dart';
import '../../../data/runtime/models/detection_model.dart';

// ---------------------------------------------------------------------------
// LaneOverlayPainter
//
// Coordinate system contract
// ──────────────────────────
// All points in [FrameProcessingResult] (DetectionModel bbox/mask, LaneModel
// polylines) are in **original-frame pixel space** — i.e. the pixel dimensions
// of the camera frame or image that was fed into the ML model BEFORE any
// letterbox resize.  The decoder already un-letterboxes model-space coords
// back to this space.
//
// The painter's job is to map those coords onto the Flutter canvas, which may
// be a different size and aspect ratio.  We do this with a single
// [_computeImageRect] call that mirrors exactly how Flutter's Image widget
// (or CameraPreview) places the content inside its box using BoxFit.contain.
//
// Live camera path
// ────────────────
// [result.frameWidth] / [result.frameHeight] carry the camera frame size.
// We compute a BoxFit.contain rect from those dimensions into the canvas and
// map every point through it — same maths as the image test path.
//
// Image / video test path
// ───────────────────────
// [sourceImageSize] overrides the frame size (used when the caller knows the
// display image size independently, e.g. ImageTestScreen).  If null, the
// result's frameWidth/frameHeight are used.
// ---------------------------------------------------------------------------
class LaneOverlayPainter extends CustomPainter {
  final FrameProcessingResult? result;

  /// Override the source image size.  If null, result.frameWidth/frameHeight
  /// are used.  Pass this from ImageTestScreen / VideoTestScreen where the
  /// displayed image size is known independently.
  final Size? sourceImageSize;

  /// Show debug overlays (mask fills, image rect border).
  final bool debugMode;

  LaneOverlayPainter(
    this.result, {
    this.sourceImageSize,
    this.debugMode = true,
  });

  // ── Coordinate helpers ────────────────────────────────────────────────────

  /// Compute the destination rect that BoxFit.contain places [imageSize]
  /// inside [canvasSize] (centred, with black bars on the short axis).
  Rect _computeImageRect(Size imageSize, Size canvasSize) {
    final fitted = applyBoxFit(BoxFit.contain, imageSize, canvasSize);
    final dest   = fitted.destination;
    final dx     = (canvasSize.width  - dest.width)  / 2;
    final dy     = (canvasSize.height - dest.height) / 2;
    return Rect.fromLTWH(dx, dy, dest.width, dest.height);
  }

  /// Map a point from original-frame pixel space to canvas space.
  Offset _toCanvas(Point p, Size canvasSize, Size srcSize, Rect imageRect) {
    final rx = p.x / srcSize.width;
    final ry = p.y / srcSize.height;
    return Offset(
      imageRect.left + rx * imageRect.width,
      imageRect.top  + ry * imageRect.height,
    );
  }

  Offset _mapXY(double x, double y, Size canvasSize, Size srcSize, Rect imageRect) =>
      _toCanvas(Point(x, y), canvasSize, srcSize, imageRect);

  // ── Paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    if (result == null) return;

    final lane       = result!.lane;
    final detections = result!.detections;

    // Resolve source image size: prefer explicit override, fall back to result.
    final srcSize = sourceImageSize ??
        Size(result!.frameWidth.toDouble(), result!.frameHeight.toDouble());

    final imageRect = _computeImageRect(srcSize, size);

    // ── DEBUG: draw image destination rect ─────────────────────────────────
    if (debugMode) {
      canvas.drawRect(
        imageRect,
        Paint()
          ..color       = Colors.cyan.withValues(alpha: 0.3)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 3.0,
      );
    }

    // ── DEBUG: fill detection masks ───────────────────────────────────────
    if (debugMode) {
      for (final det in detections) {
        if (det.mask.isNotEmpty) {
          final path  = Path();
          final first = _toCanvas(det.mask[0], size, srcSize, imageRect);
          path.moveTo(first.dx, first.dy);
          for (int i = 1; i < det.mask.length; i++) {
            final p = _toCanvas(det.mask[i], size, srcSize, imageRect);
            path.lineTo(p.dx, p.dy);
          }
          path.close();
          canvas.drawPath(
            path,
            Paint()
              ..color = Colors.cyan.withValues(alpha: 0.25)
              ..style = PaintingStyle.fill,
          );
        }
      }
    }

    // ── Lane lines ────────────────────────────────────────────────────────
    if (lane != null) {
      if (lane.centerLine.length >= 2) {
        _drawPolyline(canvas, size, srcSize, imageRect,
            lane.centerLine, Colors.green, 3.0);
      }
      if (lane.leftBoundary.length >= 2) {
        _drawPolyline(canvas, size, srcSize, imageRect,
            lane.leftBoundary, Colors.yellow, 2.0);
      }
      if (lane.rightBoundary.length >= 2) {
        _drawPolyline(canvas, size, srcSize, imageRect,
            lane.rightBoundary, Colors.yellow, 2.0);
      }
    }

    // ── Detection boxes ───────────────────────────────────────────────────
    for (final det in detections) {
      _drawDetectionBox(canvas, size, srcSize, imageRect, det);
    }

    // ── Warnings ──────────────────────────────────────────────────────────
    if (lane != null && lane.confidence < 0.35) {
      _drawWarning(canvas, size, 'Low Lane Confidence');
    }
    if (result!.overtakeDecision != null) {
      final od = result!.overtakeDecision!;
      if (od.name == 'notAllowed') {
        _drawWarning(canvas, size, 'Do Not Overtake', color: Colors.red);
      } else if (od.name == 'caution') {
        _drawWarning(canvas, size, 'Overtake with Caution',
            color: Colors.orange, yOffset: 40);
      }
    }
  }

  // ── Drawing helpers ───────────────────────────────────────────────────────

  void _drawPolyline(
    Canvas canvas,
    Size canvasSize,
    Size srcSize,
    Rect imageRect,
    List<Point> points,
    Color color,
    double strokeWidth,
  ) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color       = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round
      ..strokeJoin  = StrokeJoin.round;

    final path  = Path();
    final first = _toCanvas(points[0], canvasSize, srcSize, imageRect);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < points.length; i++) {
      final p = _toCanvas(points[i], canvasSize, srcSize, imageRect);
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDetectionBox(
    Canvas canvas,
    Size canvasSize,
    Size srcSize,
    Rect imageRect,
    DetectionModel det,
  ) {
    final tl   = _mapXY(det.xMin, det.yMin, canvasSize, srcSize, imageRect);
    final br   = _mapXY(det.xMax, det.yMax, canvasSize, srcSize, imageRect);
    final rect = Rect.fromLTRB(tl.dx, tl.dy, br.dx, br.dy);

    canvas.drawRect(
      rect,
      Paint()
        ..color       = _classColor(det.className)
        ..strokeWidth = 2
        ..style       = PaintingStyle.stroke,
    );

    final labelY = (tl.dy - 16).clamp(0.0, canvasSize.height - 18);
    (TextPainter(
      text: TextSpan(
        text: '${det.className} ${(det.confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color:      Colors.white,
          fontSize:   11,
          fontWeight: FontWeight.bold,
          shadows:    [Shadow(color: Colors.black, blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(canvas, Offset(tl.dx, labelY));
  }

  Color _classColor(String className) {
    switch (className) {
      case 'road_surface':        return Colors.green.withValues(alpha: 0.6);
      case 'road_edge':           return Colors.yellow.withValues(alpha: 1.0);
      case 'center_line_marking': return Colors.white.withValues(alpha: 1.0);
      case 'road_obstruction':    return Colors.red.withValues(alpha: 1.0);
      default:                    return Colors.blue.withValues(alpha: 1.0);
    }
  }

  void _drawWarning(
    Canvas canvas,
    Size size,
    String message, {
    Color color    = Colors.red,
    double yOffset = 0,
  }) {
    canvas.drawRect(
      Rect.fromLTWH(0, yOffset, size.width, 36),
      Paint()..color = color.withValues(alpha: 0.55),
    );
    (TextPainter(
      text: TextSpan(
        text:  message,
        style: const TextStyle(
          color:      Colors.white,
          fontSize:   16,
          fontWeight: FontWeight.bold,
          shadows:    [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout())
        .paint(canvas, Offset(10, yOffset + 8));
  }

  @override
  bool shouldRepaint(LaneOverlayPainter old) =>
      old.result != result || old.sourceImageSize != sourceImageSize;
}