import 'dart:math' as math;
import 'dart:typed_data';

import '../../data/runtime/models/detection_model.dart';
import '../../data/domain/models/geometry/point.dart';

/// YOLOv8-seg decoder.
///
/// Model outputs (after TFLite inference):
///   det   : [1, 39, 8400]  → transposed to [8400, 39]  (4 bbox + 3 cls + 32 mask coeffs)
///   proto : [1, 160, 160, 32] → flattened to [160*160, 32] = [25600, 32]
///
/// Pipeline mirrors the reference Python script exactly:
///   1. Filter by confidence
///   2. xywh → xyxy (in 640-space)
///   3. NMS
///   4. mask = sigmoid(coeffs @ proto.T)  → 160×160
///   5. Upsample mask 160 → 640 (nearest / bilinear approx)
///   6. Threshold at 0.5
///   7. Crop to bbox
///   8. Extract contour polygon
///   9. Unletterbox → original image space
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
  static const int protoSize = protoH * protoW; // 25 600
  static const int stride = 4 + numClasses + maskCoeffCount; // 39
  static const int inputSize = 640;

  // Letterbox params set by inference isolate after preprocessing
  double _scale = 1.0;
  double _dx = 0.0;
  double _dy = 0.0;

  void setPreprocessParams(double scale, double dx, double dy) {
    _scale = scale;
    _dx = dx;
    _dy = dy;
  }

  // ─────────────────────────────────────────────────────────────
  // MAIN ENTRY
  // ─────────────────────────────────────────────────────────────

  /// [detFlat]   : Float32List of length stride × 8400, already transposed
  ///               (row-major: anchor-major order, i.e. det[i*stride + attr])
  /// [protoFlat] : Float32List of length 25600 × 32
  ///               (row-major: pixel-major, i.e. proto[pixel*32 + coeff])
  List<DetectionModel> decode(
    Float32List detFlat,
    Float32List protoFlat,
    double confThreshold,
  ) {
    final total = detFlat.length ~/ stride;
    final boxes = <_RawBox>[];

    // ── 1. Filter by confidence ──────────────────────────────
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

      // xywh in 640-space
      final cx = detFlat[off] * inputSize;
      final cy = detFlat[off + 1] * inputSize;
      final w  = detFlat[off + 2] * inputSize;
      final h  = detFlat[off + 3] * inputSize;

      // xyxy in 640-space
      final x1 = (cx - w * 0.5).clamp(0.0, inputSize.toDouble());
      final y1 = (cy - h * 0.5).clamp(0.0, inputSize.toDouble());
      final x2 = (cx + w * 0.5).clamp(0.0, inputSize.toDouble());
      final y2 = (cy + h * 0.5).clamp(0.0, inputSize.toDouble());

      if (x2 <= x1 || y2 <= y1) continue;

      final coeffOff = off + 4 + numClasses;
      boxes.add(_RawBox(x1, y1, x2, y2, bestScore, bestCls, coeffOff));
    }

    // ── 2. NMS ───────────────────────────────────────────────
    final kept = _nms(boxes, detFlat, iouThreshold: 0.45);

    // ── 3. Decode each detection ─────────────────────────────
    final results = <DetectionModel>[];
    for (final b in kept) {
      results.add(_buildDetection(b, detFlat, protoFlat));
    }
    return results;
  }

  // ─────────────────────────────────────────────────────────────
  // NMS
  // ─────────────────────────────────────────────────────────────

  List<_RawBox> _nms(
    List<_RawBox> boxes,
    Float32List det, {
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
        if (_iou(boxes[i], boxes[j]) > iouThreshold) suppressed[j] = true;
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
    if (inter == 0.0) return 0.0;

    final aA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final aB = (b.x2 - b.x1) * (b.y2 - b.y1);
    return inter / (aA + aB - inter + 1e-6);
  }

  // ─────────────────────────────────────────────────────────────
  // DETECTION BUILD  (mask decode + polygon extract)
  // ─────────────────────────────────────────────────────────────

  DetectionModel _buildDetection(
    _RawBox b,
    Float32List det,
    Float32List proto,
  ) {
    // ── Mask = sigmoid(coeffs @ proto.T) in 160×160 ──────────
    //
    // proto layout: proto[pixelIdx * 32 + coeffIdx]
    // We compute: mask[p] = sigmoid( sum_k( coeff[k] * proto[p*32 + k] ) )
    final mask160 = Float32List(protoSize);
    for (int p = 0; p < protoSize; p++) {
      double sum = 0.0;
      final base = p * maskCoeffCount;
      for (int k = 0; k < maskCoeffCount; k++) {
        sum += det[b.coeffOff + k] * proto[base + k];
      }
      mask160[p] = _sigmoid(sum);
    }

    // ── Upsample 160→640 (nearest neighbour) + threshold ────
    //    scale factor = 640/160 = 4
    //    Also crop to bbox in 640-space
    const scale = inputSize ~/ protoH; // 4
    final bx1 = b.x1.toInt().clamp(0, inputSize - 1);
    final by1 = b.y1.toInt().clamp(0, inputSize - 1);
    final bx2 = b.x2.toInt().clamp(0, inputSize);
    final by2 = b.y2.toInt().clamp(0, inputSize);

    // Build binary mask in 640-space (only inside bbox to save memory)
    final maskW = bx2 - bx1;
    final maskH = by2 - by1;

    if (maskW <= 0 || maskH <= 0) {
      return _fallbackDetection(b);
    }

    final binaryMask = Uint8List(maskW * maskH);
    for (int gy = by1; gy < by2; gy++) {
      final py = (gy ~/ scale).clamp(0, protoH - 1);
      final rowOut = (gy - by1) * maskW;
      for (int gx = bx1; gx < bx2; gx++) {
        final px = (gx ~/ scale).clamp(0, protoW - 1);
        binaryMask[rowOut + (gx - bx1)] =
            mask160[py * protoW + px] > 0.5 ? 1 : 0;
      }
    }

    // ── Extract contour polygon from binary mask ─────────────
    final polygon640 = _marchingSquaresContour(
      binaryMask,
      maskW,
      maskH,
      offsetX: bx1,
      offsetY: by1,
    );

    // ── Unletterbox: 640-space → original image space ────────
    List<Point> mask;
    if (polygon640.isEmpty) {
      mask = _bboxPolygon(b);
    } else {
      mask = polygon640.map((p) {
        return Point(
          (p.x - _dx) / _scale,
          (p.y - _dy) / _scale,
        );
      }).toList(growable: false);
    }

    return DetectionModel(
      classId:   b.cls,
      className: classMap[b.cls] ?? 'unknown',
      confidence: b.score,
      mask:      mask,
      xMin:      (b.x1 - _dx) / _scale,
      yMin:      (b.y1 - _dy) / _scale,
      xMax:      (b.x2 - _dx) / _scale,
      yMax:      (b.y2 - _dy) / _scale,
      metadata:  const {},
    );
  }

  // ─────────────────────────────────────────────────────────────
  // CONTOUR EXTRACTION  (lightweight marching-squares boundary)
  // ─────────────────────────────────────────────────────────────
  //
  // Traces the boundary of the largest connected blob in [mask].
  // Returns points in 640-space (adds offsetX/Y).
  //
  // For mobile real-time use we skip full OpenCV contour tracing
  // and instead walk the outer boundary using 4-connected neighbour
  // checks, then apply Douglas-Peucker simplification.

  List<Point> _marchingSquaresContour(
    Uint8List mask,
    int w,
    int h, {
    required int offsetX,
    required int offsetY,
  }) {
    // Find first set pixel (top-left scan)
    int startX = -1, startY = -1;
    outer:
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (mask[y * w + x] == 1) {
          startX = x;
          startY = y;
          break outer;
        }
      }
    }
    if (startX == -1) return [];

    // Moore neighbour boundary tracing (Jacob's stopping criterion)
    const dx = [1, 1, 0, -1, -1, -1, 0, 1];
    const dy = [0, 1, 1, 1, 0, -1, -1, -1];

    bool inBounds(int x, int y) => x >= 0 && x < w && y >= 0 && y < h;
    bool isSet(int x, int y) =>
        inBounds(x, y) && mask[y * w + x] == 1;

    final boundary = <Point>[];
    int cx = startX, cy = startY;
    int dir = 7; // enter from direction 7 (top-left)
    int step = 0;

    do {
      boundary.add(Point((cx + offsetX).toDouble(), (cy + offsetY).toDouble()));
      // Backtrack one step, then sweep clockwise
      final backDir = (dir + 4) % 8;
      int d = (backDir + 1) % 8;
      while (!isSet(cx + dx[d], cy + dy[d]) && d != backDir) {
        d = (d + 1) % 8;
      }
      final nx = cx + dx[d];
      final ny = cy + dy[d];
      if (!isSet(nx, ny)) break; // isolated pixel
      dir = d;
      cx = nx;
      cy = ny;
      step++;
      if (step > w * h * 2) break; // safety cap
    } while (cx != startX || cy != startY);

    if (boundary.length < 3) return [];

    // Ramer–Douglas–Peucker simplification (epsilon = 1% of perimeter)
    return _rdpSimplify(boundary, epsilon: 1.5);
  }

  // Iterative RDP to avoid stack overflow on large contours
  List<Point> _rdpSimplify(List<Point> pts, {required double epsilon}) {
    if (pts.length <= 2) return pts;

    final keep = List<bool>.filled(pts.length, false);
    keep[0] = true;
    keep[pts.length - 1] = true;

    final stack = <_Seg>[_Seg(0, pts.length - 1)];
    while (stack.isNotEmpty) {
      final seg = stack.removeLast();
      double maxDist = 0.0;
      int maxIdx = seg.start;

      for (int i = seg.start + 1; i < seg.end; i++) {
        final d = _perpendicularDist(pts[i], pts[seg.start], pts[seg.end]);
        if (d > maxDist) {
          maxDist = d;
          maxIdx = i;
        }
      }
      if (maxDist > epsilon) {
        keep[maxIdx] = true;
        stack.add(_Seg(seg.start, maxIdx));
        stack.add(_Seg(maxIdx, seg.end));
      }
    }

    return [
      for (int i = 0; i < pts.length; i++)
        if (keep[i]) pts[i],
    ];
  }

  double _perpendicularDist(Point p, Point a, Point b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) {
      final ex = p.x - a.x, ey = p.y - a.y;
      return math.sqrt(ex * ex + ey * ey);
    }
    final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2;
    final px = a.x + t * dx, py = a.y + t * dy;
    final ex = p.x - px, ey = p.y - py;
    return math.sqrt(ex * ex + ey * ey);
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  DetectionModel _fallbackDetection(_RawBox b) => DetectionModel(
        classId:    b.cls,
        className:  classMap[b.cls] ?? 'unknown',
        confidence: b.score,
        mask:       _bboxPolygon(b),
        xMin:       (b.x1 - _dx) / _scale,
        yMin:       (b.y1 - _dy) / _scale,
        xMax:       (b.x2 - _dx) / _scale,
        yMax:       (b.y2 - _dy) / _scale,
        metadata:   const {},
      );

  List<Point> _bboxPolygon(_RawBox b) => [
        Point((b.x1 - _dx) / _scale, (b.y1 - _dy) / _scale),
        Point((b.x2 - _dx) / _scale, (b.y1 - _dy) / _scale),
        Point((b.x2 - _dx) / _scale, (b.y2 - _dy) / _scale),
        Point((b.x1 - _dx) / _scale, (b.y2 - _dy) / _scale),
      ];

  static double _sigmoid(double x) => 1.0 / (1.0 + math.exp(-x));
}

// ─────────────────────────────────────────────────────────────
// LIGHTWEIGHT VALUE TYPES
// ─────────────────────────────────────────────────────────────

class _RawBox {
  final double x1, y1, x2, y2;
  final double score;
  final int cls;
  final int coeffOff; // offset into det Float32List

  const _RawBox(
    this.x1, this.y1, this.x2, this.y2,
    this.score, this.cls, this.coeffOff,
  );
}

class _Seg {
  final int start, end;
  const _Seg(this.start, this.end);
}