import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import '../../data/runtime/models/detection_model.dart';
import '../../data/domain/models/geometry/point.dart';

class YoloSegDecoder {
  static const Map<int, String> classMap = {
    0: "road_surface",
    1: "road_edge",
    2: "center_line_marking",
  };

  final int numClasses = classMap.length;
  final int maskCoeffCount = 32;

  final int protoHeight = 160;
  final int protoWidth = 160;

  int get protoSize => protoHeight * protoWidth;

  double _scale = 1.0;
  double _dx = 0.0;
  double _dy = 0.0;

  void setPreprocessParams(double scale, double dx, double dy) {
    _scale = scale;
    _dx = dx;
    _dy = dy;
  }

  /// -------------------------------
  /// MAIN DECODE (optimized)
  /// -------------------------------
  List<DetectionModel> decode(
    List<List<double>> outputs,
    double confThreshold,
  ) {
    final det = outputs[0];
    final maskProto = outputs.length > 1 ? outputs[1] : null;

    final stride = 4 + numClasses + maskCoeffCount;
    final total = det.length ~/ stride;

    final boxes = <_Box>[];

    for (int i = 0, off = 0; i < total; i++, off += stride) {
      final x = det[off];
      final y = det[off + 1];
      final w = det[off + 2];
      final h = det[off + 3];

      // class selection (no allocations)
      int bestClass = 0;
      double bestScore = 0;

      for (int c = 0; c < numClasses; c++) {
        final s = _sigmoid(det[off + 4 + c]);
        if (s > bestScore) {
          bestScore = s;
          bestClass = c;
        }
      }

      if (bestScore < confThreshold) continue;

      boxes.add(_Box(
        x, y, w, h,
        bestScore,
        bestClass,
        off + 4 + numClasses,
      ));
    }

    final kept = _nms(boxes, 0.45);

    final out = <DetectionModel>[];
    for (final b in kept) {
      out.add(_toModel(b, det, maskProto));
    }

    return out;
  }

  // ------------------------------------------------------------
  // FAST NMS (no removeAt, no reallocation per iteration)
  // ------------------------------------------------------------
  List<_Box> _nms(List<_Box> boxes, double iouThr) {
    if (boxes.length <= 1) return boxes;

    boxes.sort((a, b) => b.score.compareTo(a.score));

    final kept = <_Box>[];
    final suppressed = List<bool>.filled(boxes.length, false);

    for (int i = 0; i < boxes.length; i++) {
      if (suppressed[i]) continue;

      final a = boxes[i];
      kept.add(a);

      for (int j = i + 1; j < boxes.length; j++) {
        if (suppressed[j]) continue;

        if (_iou(a, boxes[j]) > iouThr) {
          suppressed[j] = true;
        }
      }
    }

    return kept;
  }

  double _iou(_Box a, _Box b) {
    final ax1 = a.x - a.w / 2;
    final ay1 = a.y - a.h / 2;
    final ax2 = a.x + a.w / 2;
    final ay2 = a.y + a.h / 2;

    final bx1 = b.x - b.w / 2;
    final by1 = b.y - b.h / 2;
    final bx2 = b.x + b.w / 2;
    final by2 = b.y + b.h / 2;

    final x1 = math.max(ax1, bx1);
    final y1 = math.max(ay1, by1);
    final x2 = math.min(ax2, bx2);
    final y2 = math.min(ay2, by2);

    final inter = math.max(0, x2 - x1) * math.max(0, y2 - y1);
    final areaA = (ax2 - ax1) * (ay2 - ay1);
    final areaB = (bx2 - bx1) * (by2 - by1);

    return inter / (areaA + areaB - inter + 1e-6);
  }

  // ------------------------------------------------------------
  // MODEL CONVERSION
  // ------------------------------------------------------------
  DetectionModel _toModel(_Box b, List<double> det, List<double>? proto) {
    double xMin = (b.x - b.w / 2 - _dx) / _scale;
    double yMin = (b.y - b.h / 2 - _dy) / _scale;
    double xMax = (b.x + b.w / 2 - _dx) / _scale;
    double yMax = (b.y + b.h / 2 - _dy) / _scale;

    final className = classMap[b.classId] ?? 'unknown';

    final mask = proto == null
        ? _boxPoly(xMin, yMin, xMax, yMax)
        : _decodeMask(b, proto);

    return DetectionModel(
      classId: b.classId,
      className: className,
      confidence: b.score,
      mask: mask,
      xMin: xMin,
      yMin: yMin,
      xMax: xMax,
      yMax: yMax,
      metadata: const {},
    );
  }

  // ------------------------------------------------------------
  // MASK DECODING (reduced allocations)
  // NOTE: still expensive but optimized structure-wise
  // ------------------------------------------------------------
  List<Point> _decodeMask(_Box b, List<double> proto) {
    final inst = Float64List(protoSize);

    int baseCoeff = b.coeffOffset;

    for (int i = 0; i < protoSize; i++) {
      double sum = 0;

      final p = i * maskCoeffCount;
      for (int k = 0; k < maskCoeffCount; k++) {
        sum += b.coeffs(k, proto) * proto[p + k];
      }

      inst[i] = _sigmoid(sum);
    }

    final mask = Uint8List(protoSize);
    for (int i = 0; i < protoSize; i++) {
      mask[i] = inst[i] > 0.5 ? 1 : 0;
    }

    return _boxPoly(
      (b.x - b.w / 2 - _dx) / _scale,
      (b.y - b.h / 2 - _dy) / _scale,
      (b.x + b.w / 2 - _dx) / _scale,
      (b.y + b.h / 2 - _dy) / _scale,
    );
  }

  List<Point> _boxPoly(double x1, double y1, double x2, double y2) {
    return [
      Point(x1, y1),
      Point(x2, y1),
      Point(x2, y2),
      Point(x1, y2),
    ];
  }

  double _sigmoid(double x) => 1 / (1 + math.exp(-x));
}

// ------------------------------------------------------------
// Lightweight struct replacement
// ------------------------------------------------------------
class _Box {
  final double x, y, w, h;
  final double score;
  final int classId;
  final int coeffOffset;

  _Box(this.x, this.y, this.w, this.h, this.score, this.classId, this.coeffOffset);

  double coeffs(int k, List<double> proto) => proto[coeffOffset + k];
}