import 'package:flutter/material.dart';

import '../../../data/domain/models/geometry/point.dart';
import '../../../data/runtime/models/detection_model.dart';
import '../../../data/runtime/models/frame_processing_result.dart';

// ---------------------------------------------------------------------------
// LaneOverlayPainter
//
// Coordinate contract
// ───────────────────
// All points in [FrameProcessingResult] (bbox xMin/yMin/xMax/yMax, mask
// polygon, LaneModel polylines) are in **original-frame pixel space** — the
// pixel dimensions of the camera frame or image fed to the ML model BEFORE
// any letterbox resize. The decoder unletterboxes model-space coords back to
// this space before building DetectionModel.
//
// The painter maps those coords onto the Flutter canvas, which may be a
// different size and aspect ratio, using a single BoxFit.contain transform
// that mirrors exactly how Flutter's Image widget (or CameraPreview) places
// its content.
//
// Live camera:  result.frameWidth / frameHeight   → source size
// Image / video test: [sourceImageSize] override  → source size (preferred)
//
// Performance notes
// ─────────────────
// • TextPainter instances are cached across repaints keyed by (className, conf).
//   TextPainter.layout() is expensive; this cuts it from O(n detections) per
//   frame to O(new detections).
// • Mask and lane paths are constructed once per paint call but kept as
//   local Path objects (not stored) because the result reference changes
//   every frame anyway.
// • shouldRepaint checks by result identity (reference equality), which is
//   correct because FrameProcessingResult is a new object every frame.
// ---------------------------------------------------------------------------

class LaneOverlayPainter extends CustomPainter {
  final FrameProcessingResult? result;

  /// Override source image dimensions. If null, result.frameWidth/Height used.
  final Size? sourceImageSize;

  /// When false, suppresses debug overlays (mask fill, image rect border).
  /// Always false in production / live camera.
  final bool debugMode;

  LaneOverlayPainter(
    this.result, {
    this.sourceImageSize,
    this.debugMode = false,
  });

  // ── Label cache (persists across repaints while painter instance lives) ──
  // Key: "$className $confPct" → laid-out TextPainter
  final Map<String, TextPainter> _labelCache = {};

  // ── Class colours ─────────────────────────────────────────────────────────
  static const _classColors = <String, Color>{
    'road_surface':        Color(0x9900C853),  // green 60 %
    'road_edge':           Color(0xFFFFD600),  // amber 100 %
    'center_line_marking': Color(0xFFFFFFFF),  // white 100 %
    'road_obstruction':    Color(0xFFFF1744),  // red 100 %
  };
  static const _defaultColor = Color(0xFF2979FF); // blue

  static Color _classColor(String name) =>
      _classColors[name] ?? _defaultColor;

  // ── Paints (const-like; constructed once) ─────────────────────────────────
  static final _debugRectPaint = Paint()
    ..color       = const Color(0x4D00E5FF) // cyan 30 %
    ..style       = PaintingStyle.stroke
    ..strokeWidth = 2.0;

  static final _maskFillPaint = Paint()
    ..color = const Color(0x4000E5FF) // cyan 25 %
    ..style = PaintingStyle.fill;

  static final _centerLinePaint = Paint()
    ..color       = const Color(0xFF00E676) // green
    ..strokeWidth = 3.0
    ..style       = PaintingStyle.stroke
    ..strokeCap   = StrokeCap.round
    ..strokeJoin  = StrokeJoin.round;

  static final _boundaryPaint = Paint()
    ..color       = const Color(0xFFFFD600) // amber
    ..strokeWidth = 2.0
    ..style       = PaintingStyle.stroke
    ..strokeCap   = StrokeCap.round
    ..strokeJoin  = StrokeJoin.round;

  // ── Coordinate helpers ────────────────────────────────────────────────────

  /// Rect that BoxFit.contain places [src] inside [canvas] (centred).
  static Rect _imageRect(Size src, Size canvas) {
    final fitted = applyBoxFit(BoxFit.contain, src, canvas);
    final dst    = fitted.destination;
    return Rect.fromLTWH(
      (canvas.width  - dst.width)  / 2,
      (canvas.height - dst.height) / 2,
      dst.width,
      dst.height,
    );
  }

  /// Map a single [Point] from original-frame space to canvas space.
  static Offset _map(Point p, Size src, Rect ir) => Offset(
        ir.left + (p.x / src.width)  * ir.width,
        ir.top  + (p.y / src.height) * ir.height,
      );

  static Offset _mapXY(double x, double y, Size src, Rect ir) =>
      _map(Point(x, y), src, ir);

  // ── Path builders ─────────────────────────────────────────────────────────

  static Path _polylinePath(List<Point> pts, Size src, Rect ir) {
    final path  = Path();
    final first = _map(pts[0], src, ir);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < pts.length; i++) {
      final o = _map(pts[i], src, ir);
      path.lineTo(o.dx, o.dy);
    }
    return path;
  }

  static Path? _maskPath(List<Point> pts, Size src, Rect ir) {
    if (pts.isEmpty) return null;
    final path  = Path();
    final first = _map(pts[0], src, ir);
    path.moveTo(first.dx, first.dy);
    for (int i = 1; i < pts.length; i++) {
      final o = _map(pts[i], src, ir);
      path.lineTo(o.dx, o.dy);
    }
    path.close();
    return path;
  }

  // ── Paint ─────────────────────────────────────────────────────────────────

  @override
  void paint(Canvas canvas, Size size) {
    final r = result;
    if (r == null) return;

    final detections = r.detections;
    final lane       = r.lane;

    // Resolve source size
    final src = sourceImageSize ??
        (r.frameWidth > 0 && r.frameHeight > 0
            ? Size(r.frameWidth.toDouble(), r.frameHeight.toDouble())
            : null);

    // If we have no size information at all we cannot map coordinates.
    if (src == null || src.isEmpty) return;

    final ir = _imageRect(src, size);

    // ── 1. DEBUG: image dest rect ────────────────────────────────────────
    if (debugMode) {
      canvas.drawRect(ir, _debugRectPaint);
    }

    // ── 2. Mask fills (debug only — polygon masks are drawn as stroked
    //       outlines in production to avoid covering road content) ────────
    if (debugMode) {
      for (final det in detections) {
        final path = _maskPath(det.mask, src, ir);
        if (path != null) canvas.drawPath(path, _maskFillPaint);
      }
    }

    // ── 3. Mask outlines (always — shows segmentation boundary) ──────────
    for (final det in detections) {
      if (det.mask.length >= 3) {
        final path = _maskPath(det.mask, src, ir);
        if (path != null) {
          canvas.drawPath(
            path,
            Paint()
              ..color       = _classColor(det.className).withValues(alpha: 0.75)
              ..style       = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
        }
      }
    }

    // ── 4. Lane lines ─────────────────────────────────────────────────────
    if (lane != null) {
      if (lane.centerLine.length >= 2) {
        canvas.drawPath(_polylinePath(lane.centerLine, src, ir), _centerLinePaint);
      }
      if (lane.leftBoundary.length >= 2) {
        canvas.drawPath(_polylinePath(lane.leftBoundary, src, ir), _boundaryPaint);
      }
      if (lane.rightBoundary.length >= 2) {
        canvas.drawPath(_polylinePath(lane.rightBoundary, src, ir), _boundaryPaint);
      }
    }

    // ── 5. Detection bounding boxes + labels ──────────────────────────────
    for (final det in detections) {
      _drawBox(canvas, size, src, ir, det);
    }

    // ── 6. Warning banners (stacked, non-overlapping) ─────────────────────
    double warningY = 0;
    if (lane != null && lane.confidence < 0.35) {
      warningY = _drawWarning(canvas, size, 'Low lane confidence',
          color: const Color(0xFFFF6D00), y: warningY);
    }

    final od = r.overtakeDecision;
    if (od != null) {
      if (od.name == 'notAllowed') {
        warningY = _drawWarning(canvas, size, 'Do not overtake',
            color: const Color(0xFFD50000), y: warningY);
      } else if (od.name == 'caution') {
        _drawWarning(canvas, size, 'Overtake with caution',
            color: const Color(0xFFFF6D00), y: warningY);
      }
    }
  }

  // ── Box + label ───────────────────────────────────────────────────────────

  void _drawBox(
    Canvas canvas,
    Size canvasSize,
    Size src,
    Rect ir,
    DetectionModel det,
  ) {
    final tl   = _mapXY(det.xMin, det.yMin, src, ir);
    final br   = _mapXY(det.xMax, det.yMax, src, ir);
    final rect = Rect.fromLTRB(tl.dx, tl.dy, br.dx, br.dy);

    // Skip degenerate boxes (can happen on edge detections)
    if (rect.width < 1 || rect.height < 1) return;

    canvas.drawRect(
      rect,
      Paint()
        ..color       = _classColor(det.className)
        ..strokeWidth = 1.5
        ..style       = PaintingStyle.stroke,
    );

    _drawLabel(canvas, canvasSize, det, tl);
  }

  void _drawLabel(
    Canvas canvas,
    Size canvasSize,
    DetectionModel det,
    Offset tl,
  ) {
    final confPct = (det.confidence * 100).toStringAsFixed(0);
    final key     = '${det.className} $confPct%';

    // Use cached painter; create + layout only on first encounter.
    final tp = _labelCache.putIfAbsent(key, () {
      final p = TextPainter(
        text: TextSpan(
          text:  key,
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   11,
            fontWeight: FontWeight.w600,
            shadows:    [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      return p;
    });

    // Clamp label above box but within canvas
    final labelY = (tl.dy - tp.height - 2).clamp(0.0, canvasSize.height - tp.height);
    final labelX = tl.dx.clamp(0.0, canvasSize.width  - tp.width);

    // Pill background for readability
    final bgRect = Rect.fromLTWH(labelX - 2, labelY - 1, tp.width + 4, tp.height + 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
      Paint()..color = _classColor(det.className).withValues(alpha: 0.7),
    );

    tp.paint(canvas, Offset(labelX, labelY));
  }

  // ── Warning banner ────────────────────────────────────────────────────────

  /// Draws a full-width banner at [y] and returns the y of the next banner.
  double _drawWarning(
    Canvas canvas,
    Size size,
    String message, {
    required Color color,
    required double y,
  }) {
    const h = 34.0;
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, h),
      Paint()..color = color.withValues(alpha: 0.72),
    );

    final tp = TextPainter(
      text: TextSpan(
        text:  message,
        style: const TextStyle(
          color:      Colors.white,
          fontSize:   15,
          fontWeight: FontWeight.w700,
          shadows:    [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(12, y + (h - tp.height) / 2));
    return y + h;
  }

  // ── Repaint guard ─────────────────────────────────────────────────────────

  @override
  bool shouldRepaint(LaneOverlayPainter old) =>
      !identical(old.result, result) ||
      old.sourceImageSize != sourceImageSize ||
      old.debugMode != debugMode;
}