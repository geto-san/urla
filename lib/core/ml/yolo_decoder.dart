import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../data/runtime/models/detection_model.dart';
import '../../data/domain/models/geometry/point.dart';

class YoloSegDecoder {
  static const Map<int, String> classMap = {
    0: "road_surface",
    1: "road_edge",
    2: "center_line_marking",   
    // 3: "road_obstruction",
  };

  final int numClasses;   // set externally to match model output
  final int maskCoeffCount = 32;
  final int protoHeight = 160;
  final int protoWidth = 160;
  int get protoSize => protoHeight * protoWidth;

  /// If true, the model has a separate objectness confidence channel.
  /// If false, class scores are already confidences (YOLOv8 default export).
  final bool hasObjectness;

  // Letterbox parameters set before each frame
  double _preprocessScale = 1.0;
  double _preprocessDx    = 0.0;
  double _preprocessDy    = 0.0;

  YoloSegDecoder({
    this.hasObjectness = false,
    int? numClasses,
  }) : numClasses = numClasses ?? classMap.length;

  void setPreprocessParams(double scale, double dx, double dy) {
    _preprocessScale = scale;
    _preprocessDx    = dx;
    _preprocessDy    = dy;
  }

  List<DetectionModel> decode(
    List<List<double>> outputs,
    double confThreshold,
  ) {
    final detections = outputs[0];
    final maskProto  = outputs.length > 1 ? outputs[1] : null;

    // Compute how many attributes each anchor has.
    // 4 (bbox) + (1 if objectness) + numClasses + maskCoeffCount
    const int bboxAttrs = 4;
    final int confAttrs = hasObjectness ? 1 : 0;
    final int classAttrs = numClasses;
    final int maskAttrs  = maskCoeffCount;
    final int attributesPerDetection =
        bboxAttrs + confAttrs + classAttrs + maskAttrs;

    final int totalDetections =
        (detections.length / attributesPerDetection).floor();

    final boxes = <_DetectionBox>[];

    for (int i = 0; i < totalDetections; i++) {
      final offset = i * attributesPerDetection;

      // Bounding box
      final x = detections[offset];
      final y = detections[offset + 1];
      final w = detections[offset + 2];
      final h = detections[offset + 3];

      // Objectness (optional)
      double objectness = 1.0;
      int classStart = offset + bboxAttrs;
      if (hasObjectness) {
        objectness =
            1.0 / (1.0 + math.exp(-detections[offset + bboxAttrs]));
        classStart += 1;
      }

      // Class scores
      int bestClassId = -1;
      double bestScore = -1.0;
      for (int c = 0; c < numClasses; c++) {
        final raw = detections[classStart + c];
        final score = 1.0 / (1.0 + math.exp(-raw));
        if (score > bestScore) {
          bestScore = score;
          bestClassId = c;
        }
      }

      final combinedConf = objectness * bestScore;
      if (combinedConf < confThreshold) continue;

      // Mask coefficients
      final maskCoeffs = detections.sublist(
        classStart + numClasses,
        classStart + numClasses + maskAttrs,
      );

      boxes.add(_DetectionBox(
        x: x,
        y: y,
        w: w,
        h: h,
        confidence: combinedConf,
        classId: bestClassId,
        maskCoeffs: List<double>.from(maskCoeffs),
      ));
    }

    // Apply NMS and decode masks
    final filtered = _nonMaxSuppression(boxes, 0.45);
    return filtered
        .map((box) => _toDetectionModel(box, maskProto))
        .toList();
  }

  // ───────────────────────────────────────────────────────────────
  // NMS / IOU (unchanged)
  // ───────────────────────────────────────────────────────────────
  List<_DetectionBox> _nonMaxSuppression(
    List<_DetectionBox> boxes,
    double iouThreshold,
  ) {
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
    final result = <_DetectionBox>[];
    while (boxes.isNotEmpty) {
      final best = boxes.removeAt(0);
      result.add(best);
      boxes =
          boxes.where((b) => _iou(best, b) < iouThreshold).toList();
    }
    return result;
  }

  double _iou(_DetectionBox a, _DetectionBox b) {
    final x1 = math.max(a.x - a.w / 2, b.x - b.w / 2);
    final y1 = math.max(a.y - a.h / 2, b.y - b.h / 2);
    final x2 = math.min(a.x + a.w / 2, b.x + b.w / 2);
    final y2 = math.min(a.y + a.h / 2, b.y + b.h / 2);
    final inter = math.max(0, x2 - x1) * math.max(0, y2 - y1);
    final areaA = a.w * a.h;
    final areaB = b.w * b.h;
    return inter / (areaA + areaB - inter + 1e-6);
  }

  // ───────────────────────────────────────────────────────────────
  // DetectionModel factory (with un‑letterbox)
  // ───────────────────────────────────────────────────────────────
  DetectionModel _toDetectionModel(
      _DetectionBox box, List<double>? maskProto) {
    final className = classMap[box.classId] ?? 'unknown';
    double xMin = box.x - box.w / 2;
    double yMin = box.y - box.h / 2;
    double xMax = box.x + box.w / 2;
    double yMax = box.y + box.h / 2;

    // Un‑letterbox
    xMin = (xMin - _preprocessDx) / _preprocessScale;
    yMin = (yMin - _preprocessDy) / _preprocessScale;
    xMax = (xMax - _preprocessDx) / _preprocessScale;
    yMax = (yMax - _preprocessDy) / _preprocessScale;

    // Mask
    List<Point> mask;
    if (maskProto != null) {
      mask = _decodeMask(box, maskProto);
    } else {
      mask = _boxToPolygon(xMin, yMin, xMax, yMax);
    }

    return DetectionModel(
      classId: box.classId,
      className: className,
      confidence: box.confidence,
      mask: mask,
      xMin: xMin,
      yMin: yMin,
      xMax: xMax,
      yMax: yMax,
      metadata: {'x': box.x, 'y': box.y, 'w': box.w, 'h': box.h},
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Mask decoding (NHWC proto – unchanged)
  // ───────────────────────────────────────────────────────────────
  List<Point> _decodeMask(_DetectionBox box, List<double> maskProto) {
    final instanceMask = Float64List(protoSize);
    for (int i = 0; i < protoSize; i++) {
      double sum = 0.0;
      final base = i * maskCoeffCount;
      for (int k = 0; k < maskCoeffCount; k++) {
        sum += box.maskCoeffs[k] * maskProto[base + k];
      }
      instanceMask[i] = sum;
    }

    final binaryMask = Uint8List(protoSize);
    for (int i = 0; i < protoSize; i++) {
      final sigmoid = 1.0 / (1.0 + math.exp(-instanceMask[i]));
      binaryMask[i] = sigmoid > 0.5 ? 1 : 0;
    }

    final contours = _traceContours(binaryMask, protoWidth, protoHeight);
    if (contours.isEmpty) {
      return _boxToPolygon(
        box.x - box.w / 2,
        box.y - box.h / 2,
        box.x + box.w / 2,
        box.y + box.h / 2,
      );
    }

    final bestContour = _largestContour(contours);
    const int maxContourPoints = 200;
    final step = (bestContour.length / maxContourPoints)
        .ceil()
        .clamp(1, bestContour.length);
    final sampled = <img.Point>[];
    for (int i = 0; i < bestContour.length; i += step) {
      sampled.add(bestContour[i]);
    }

    // Scale from proto (160) to model (640) then un‑letterbox
    const double protoScale = 640.0 / 160.0;
    return sampled.map((p) {
      double mx = p.x * protoScale;
      double my = p.y * protoScale;
      return Point(
        (mx - _preprocessDx) / _preprocessScale,
        (my - _preprocessDy) / _preprocessScale,
      );
    }).toList();
  }

  // ───────────────────────────────────────────────────────────────
  // Contour tracing (unchanged)
  // ───────────────────────────────────────────────────────────────
  List<List<img.Point>> _traceContours(Uint8List binary, int w, int h) {
    final visited = Uint8List(w * h);
    final contours = <List<img.Point>>[];

    const dx = [-1, 0, 1, 1, 1, 0, -1, -1];
    const dy = [-1, -1, -1, 0, 1, 1, 1, 0];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = y * w + x;
        if (binary[idx] == 0 || visited[idx] == 1) continue;

        // Ensure boundary pixel
        bool isBoundary = false;
        for (int d = 0; d < 8; d++) {
          final nx = x + dx[d], ny = y + dy[d];
          if (nx >= 0 && nx < w && ny >= 0 && ny < h &&
              binary[ny * w + nx] == 0) {
            isBoundary = true;
            break;
          }
        }
        if (!isBoundary) continue;

        final contour = <img.Point>[];
        int startX = x, startY = y;
        int cx = x, cy = y;
        contour.add(img.Point(cx, cy));
        visited[cx + cy * w] = 1;

        int nextDir = 6, count = 0;
        do {
          bool moved = false;
          for (int i = 0; i < 8; i++) {
            int dir = (nextDir + i) % 8;
            int nx = cx + dx[dir], ny = cy + dy[dir];
            if (nx >= 0 && nx < w && ny >= 0 && ny < h &&
                binary[ny * w + nx] != 0) {
              cx = nx;
              cy = ny;
              nextDir = (dir + 6) % 8;
              moved = true;
              break;
            }
          }
          if (!moved) break;
          if (cx == startX && cy == startY) break;
          contour.add(img.Point(cx, cy));
          visited[cx + cy * w] = 1;
          count++;
        } while (count < w * h * 2);

        if (contour.isNotEmpty) contours.add(contour);

        // Flood‑fill interior
        int insideX = startX + 1;
        if (insideX < w && binary[startY * w + insideX] != 0) {
          _floodFill(binary, visited, insideX, startY, w, h);
        }
      }
    }
    return contours;
  }

  void _floodFill(
      Uint8List binary, Uint8List visited,
      int startX, int startY, int w, int h) {
    final queue = Queue<(int, int)>();
    queue.add((startX, startY));
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();
      if (x < 0 || x >= w || y < 0 || y >= h) continue;
      final idx = y * w + x;
      if (binary[idx] == 0 || visited[idx] == 1) continue;
      visited[idx] = 1;
      queue.add((x + 1, y));
      queue.add((x - 1, y));
      queue.add((x, y + 1));
      queue.add((x, y - 1));
    }
  }

  List<img.Point> _largestContour(List<List<img.Point>> contours) {
    double bestArea = -1;
    List<img.Point> best = contours.first;
    for (final contour in contours) {
      double area = 0;
      for (int i = 0; i < contour.length; i++) {
        final p1 = contour[i];
        final p2 = contour[(i + 1) % contour.length];
        area += (p1.x * p2.y - p2.x * p1.y).abs();
      }
      area /= 2.0;
      if (area > bestArea) {
        bestArea = area;
        best = contour;
      }
    }
    return best;
  }

  List<Point> _boxToPolygon(
      double xMin, double yMin, double xMax, double yMax) {
    return [
      Point(xMin, yMin),
      Point(xMax, yMin),
      Point(xMax, yMax),
      Point(xMin, yMax),
    ];
  }
}

class _DetectionBox {
  final double x, y, w, h;
  final double confidence;
  final int classId;
  final List<double> maskCoeffs;
  _DetectionBox({
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.confidence,
    required this.classId,
    required this.maskCoeffs,
  });
}