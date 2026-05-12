import 'dart:math' as math;
import 'dart:typed_data';

import '../../data/runtime/models/detection_model.dart';
import '../../data/domain/models/geometry/point.dart';

class YoloSegDecoder {
  static const Map<int, String> classMap = {
    0: 'road_surface',
    1: 'road_edge',
    2: 'center_line_marking',
  };

  static const int numClasses = 3;
  static const int maskCoeffCount = 32;
  static const int protoH = 160;
  static const int protoW = 160;
  static const int protoSize = protoH * protoW;
  static const int stride = 4 + numClasses + maskCoeffCount;
  static const int inputSize = 640;

  static const int protoScale = inputSize ~/ protoH;

  double _scale = 1.0;
  double _dx = 0.0;
  double _dy = 0.0;

  void setPreprocessParams(double scale, double dx, double dy) {
    _scale = scale;
    _dx = dx;
    _dy = dy;
  }

  List<DetectionModel> decode(
    Float32List detFlat,
    Float32List protoFlat,
    double confThreshold,
  ) {
    final total = detFlat.length ~/ stride;
    final boxes = <_RawBox>[];

    for (int i = 0; i < total; i++) {
      final off = i * stride;

      int bestCls = 0;
      double bestScore = 0.0;

      for (int c = 0; c < numClasses; c++) {
        final s = _sigmoid(detFlat[off + 4 + c]);
        if (s > bestScore) {
          bestScore = s;
          bestCls = c;
        }
      }

      if (bestScore < confThreshold) continue;

      final cx = detFlat[off] * inputSize;
      final cy = detFlat[off + 1] * inputSize;
      final w = detFlat[off + 2] * inputSize;
      final h = detFlat[off + 3] * inputSize;

      final x1 = (cx - w * 0.5).clamp(0.0, inputSize.toDouble());
      final y1 = (cy - h * 0.5).clamp(0.0, inputSize.toDouble());
      final x2 = (cx + w * 0.5).clamp(0.0, inputSize.toDouble());
      final y2 = (cy + h * 0.5).clamp(0.0, inputSize.toDouble());

      if (x2 <= x1 || y2 <= y1) continue;

      boxes.add(
        _RawBox(x1, y1, x2, y2, bestScore, bestCls, off + 4 + numClasses),
      );
    }

    final kept = _nms(boxes, iouThreshold: 0.45);

    final results = <DetectionModel>[];

    for (final b in kept) {
      results.add(_buildDetection(b, detFlat, protoFlat));
    }

    return results;
  }

  List<_RawBox> _nms(
    List<_RawBox> boxes, {
    required double iouThreshold,
  }) {
    if (boxes.isEmpty) return boxes;

    boxes.sort((a, b) => b.score.compareTo(a.score));

    final suppressed = List<bool>.filled(boxes.length, false);
    final kept = <_RawBox>[];

    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;

      kept.add(boxes[i]);

      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;

        if (_iou(boxes[i], boxes[j]) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return kept;
  }

  double _iou(_RawBox a, _RawBox b) {
    final x1 = math.max(a.x1, b.x1);
    final y1 = math.max(a.y1, b.y1);
    final x2 = math.min(a.x2, b.x2);
    final y2 = math.min(a.y2, b.y2);

    final inter = math.max(0.0, x2 - x1) * math.max(0.0, y2 - y1);
    if (inter <= 0) return 0.0;

    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);

    return inter / (areaA + areaB - inter + 1e-6);
  }

  DetectionModel _buildDetection(
    _RawBox b,
    Float32List det,
    Float32List proto,
  ) {
    final bx1 = b.x1.toInt().clamp(0, inputSize - 1);
    final by1 = b.y1.toInt().clamp(0, inputSize - 1);
    final bx2 = b.x2.toInt().clamp(0, inputSize);
    final by2 = b.y2.toInt().clamp(0, inputSize);

    final maskW = bx2 - bx1;
    final maskH = by2 - by1;

    if (maskW <= 0 || maskH <= 0) {
      return _fallbackDetection(b);
    }

    final binaryMask = Uint8List(maskW * maskH);

    final px1 = bx1 ~/ protoScale;
    final py1 = by1 ~/ protoScale;
    final px2 = bx2 ~/ protoScale;
    final py2 = by2 ~/ protoScale;

    final coeff = Float32List(maskCoeffCount);

    for (int k = 0; k < maskCoeffCount; k++) {
      coeff[k] = det[b.coeffOff + k];
    }

    for (int py = py1; py < py2; py++) {
      final protoRow = py * protoW;

      for (int px = px1; px < px2; px++) {
        final protoIndex = (protoRow + px) * maskCoeffCount;

        double sum = 0.0;

        for (int k = 0; k < maskCoeffCount; k++) {
          sum += coeff[k] * proto[protoIndex + k];
        }

        final val = _sigmoid(sum);

        if (val > 0.5) {
          final gx = px * protoScale;
          final gy = py * protoScale;

          for (int y = gy; y < gy + protoScale && y < by2; y++) {
            final row = (y - by1) * maskW;

            for (int x = gx; x < gx + protoScale && x < bx2; x++) {
              if (x >= bx1 && y >= by1) {
                binaryMask[row + (x - bx1)] = 1;
              }
            }
          }
        }
      }
    }

    final polygon640 = _marchingSquaresContour(
      binaryMask,
      maskW,
      maskH,
      offsetX: bx1,
      offsetY: by1,
    );

    List<Point> mask;

    if (polygon640.isEmpty) {
      mask = _bboxPolygon(b);
    } else {
      mask = polygon640
          .map((p) => Point(
                (p.x - _dx) / _scale,
                (p.y - _dy) / _scale,
              ))
          .toList(growable: false);
    }

    return DetectionModel(
      classId: b.cls,
      className: classMap[b.cls] ?? 'unknown',
      confidence: b.score,
      mask: mask,
      xMin: (b.x1 - _dx) / _scale,
      yMin: (b.y1 - _dy) / _scale,
      xMax: (b.x2 - _dx) / _scale,
      yMax: (b.y2 - _dy) / _scale,
      metadata: const {},
    );
  }

  List<Point> _bboxPolygon(_RawBox b) {
    return [
      Point((b.x1 - _dx) / _scale, (b.y1 - _dy) / _scale),
      Point((b.x2 - _dx) / _scale, (b.y1 - _dy) / _scale),
      Point((b.x2 - _dx) / _scale, (b.y2 - _dy) / _scale),
      Point((b.x1 - _dx) / _scale, (b.y2 - _dy) / _scale),
    ];
  }

  DetectionModel _fallbackDetection(_RawBox b) {
    return DetectionModel(
      classId: b.cls,
      className: classMap[b.cls] ?? 'unknown',
      confidence: b.score,
      mask: _bboxPolygon(b),
      xMin: (b.x1 - _dx) / _scale,
      yMin: (b.y1 - _dy) / _scale,
      xMax: (b.x2 - _dx) / _scale,
      yMax: (b.y2 - _dy) / _scale,
      metadata: const {},
    );
  }

  List<Point> _marchingSquaresContour(
    Uint8List mask,
    int w,
    int h, {
    required int offsetX,
    required int offsetY,
  }) {
    final pts = <Point>[];

    for (int y = 0; y < h; y++) {
      final row = y * w;

      for (int x = 0; x < w; x++) {
        if (mask[row + x] == 1) {
          pts.add(Point((x + offsetX).toDouble(), (y + offsetY).toDouble()));
        }
      }
    }

    if (pts.length < 5) return [];

    return _rdpSimplify(pts, epsilon: 1.5);
  }

  List<Point> _rdpSimplify(List<Point> pts, {required double epsilon}) {
    if (pts.length < 3) return pts;

    final result = <Point>[pts.first];

    for (int i = 1; i < pts.length - 1; i++) {
      final d = _perpendicularDist(pts[i], pts.first, pts.last);

      if (d > epsilon) {
        result.add(pts[i]);
      }
    }

    result.add(pts.last);

    return result;
  }

  double _perpendicularDist(Point p, Point a, Point b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;

    final mag = dx * dx + dy * dy;

    if (mag == 0) {
      final ex = p.x - a.x;
      final ey = p.y - a.y;
      return math.sqrt(ex * ex + ey * ey);
    }

    final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / mag;

    final px = a.x + t * dx;
    final py = a.y + t * dy;

    final ex = p.x - px;
    final ey = p.y - py;

    return math.sqrt(ex * ex + ey * ey);
  }

  double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }
}

class _RawBox {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double score;
  final int cls;
  final int coeffOff;

  _RawBox(
    this.x1,
    this.y1,
    this.x2,
    this.y2,
    this.score,
    this.cls,
    this.coeffOff,
  );
}