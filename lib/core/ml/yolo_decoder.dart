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

  final int numClasses = classMap.length; // 3 for now
  final int maskCoeffCount = 32; // YOLOv8-seg
  final int protoHeight = 160; // typical mask proto size
  final int protoWidth = 160;
  int get protoSize => protoHeight * protoWidth; // 25600

  /// Main decode function – takes raw outputs from the interpreter.
  ///
  /// [outputs] : list of tensors:
  ///   outputs[0] = detection output – shape [1, N, 4+1+numClasses+32] = [1, N, 42],
  ///   outputs[1] = proto mask       – shape [1, 32, 160, 160]
  List<DetectionModel> decode(
    List<List<double>> outputs,
    double confThreshold,
  ) {
    final detections = outputs[0];
    final maskProto = outputs.length > 1 ? outputs[1] : null;

    // Calculate number of detections per anchor
    const int bboxAttrs = 4; // x, y, w, h
    const int confAttr = 1; // objectness confidence
    final int classAttrs = numClasses; // per‑class scores
    final int maskAttrs = maskCoeffCount; // 32
    final int attributesPerDetection =
        bboxAttrs + confAttr + classAttrs + maskAttrs; // 42
    final int totalDetections = (detections.length / attributesPerDetection)
        .floor();

    final boxes = <_DetectionBox>[];

    for (int i = 0; i < totalDetections; i++) {
      final offset = i * attributesPerDetection;
      final x = detections[offset];
      final y = detections[offset + 1];
      final w = detections[offset + 2];
      final h = detections[offset + 3];
      final confidence = detections[offset + 4];

      // Class scores – find the class with max probability
      int bestClassId = -1;
      double bestScore = -1;
      for (int c = 0; c < numClasses; c++) {
        final score = detections[offset + 5 + c];
        if (score > bestScore) {
          bestScore = score;
          bestClassId = c;
        }
      }

      // Multiply objectness × class probability (YOLOv8 convention)
      final combinedConf = confidence * bestScore;
      if (combinedConf < confThreshold) continue;

      // Extract mask coefficients (32 floats)
      final maskCoeffs = detections.sublist(
        offset + 5 + numClasses,
        offset + 5 + numClasses + maskAttrs,
      );

      boxes.add(
        _DetectionBox(
          x: x,
          y: y,
          w: w,
          h: h,
          confidence: combinedConf,
          classId: bestClassId,
          maskCoeffs: List<double>.from(maskCoeffs),
        ),
      );
    }

    // Apply NMS
    final filtered = _nonMaxSuppression(boxes, 0.45);

    // Convert to DetectionModel with real masks
    return filtered.map((box) => _toDetectionModel(box, maskProto)).toList();
  }

  // ---------------------------------------------------------------------------
  // NMS, IOU (unchanged, but using _DetectionBox.x,y,w,h)
  // ---------------------------------------------------------------------------
  List<_DetectionBox> _nonMaxSuppression(
    List<_DetectionBox> boxes,
    double iouThreshold,
  ) {
    boxes.sort((a, b) => b.confidence.compareTo(a.confidence));
    final result = <_DetectionBox>[];
    while (boxes.isNotEmpty) {
      final best = boxes.removeAt(0);
      result.add(best);
      boxes = boxes.where((b) => _iou(best, b) < iouThreshold).toList();
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

  // ---------------------------------------------------------------------------
  // DetectionModel factory
  // ---------------------------------------------------------------------------
  DetectionModel _toDetectionModel(_DetectionBox box, List<double>? maskProto) {
    final className = classMap[box.classId] ?? 'unknown';
    final xMin = box.x - box.w / 2;
    final yMin = box.y - box.h / 2;
    final xMax = box.x + box.w / 2;
    final yMax = box.y + box.h / 2;

    // Build mask polygon
    List<Point> mask;
    if (maskProto != null) {
      mask = _decodeMask(box, maskProto);
    } else {
      // fallback to bounding box polygon
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

  // ---------------------------------------------------------------------------
  // MASK DECODING – with custom contour tracing
  // ---------------------------------------------------------------------------
  List<Point> _decodeMask(_DetectionBox box, List<double> maskProto) {
    // 1. Multiply mask coefficients with proto mask → (160, 160) instance mask
    final instanceMask = Float64List(protoSize);
    for (int k = 0; k < maskCoeffCount; k++) {
      final coeff = box.maskCoeffs[k];
      final channelStart = k * protoSize;
      for (int i = 0; i < protoSize; i++) {
        instanceMask[i] += coeff * maskProto[channelStart + i];
      }
    }

    // 2. Sigmoid + threshold → binary image (1 byte per pixel)
    final binaryMask = Uint8List(protoSize);
    for (int i = 0; i < protoSize; i++) {
      final sigmoid = 1.0 / (1.0 + math.exp(-instanceMask[i]));
      binaryMask[i] = sigmoid > 0.5 ? 1 : 0; // use 1 for foreground
    }

    // 3. Extract contours using custom tracer
    final contours = _traceContours(binaryMask, protoWidth, protoHeight);
    if (contours.isEmpty) {
      return _boxToPolygon(
        box.x - box.w / 2,
        box.y - box.h / 2,
        box.x + box.w / 2,
        box.y + box.h / 2,
      );
    }

    // 4. Select the contour with the largest area
    final bestContour = _largestContour(contours);

    // 4. Downsample contour to prevent oversized JSON serialisation
    const int maxContourPoints = 200;
    final step = (bestContour.length / maxContourPoints).ceil().clamp(
      1,
      bestContour.length,
    );
    final sampled = <img.Point>[];
    for (int i = 0; i < bestContour.length; i += step) {
      sampled.add(bestContour[i]);
    }

    // 5. Scale from proto size (160) to model input size (640)
    const double scale = 640.0 / 160.0;
    return sampled.map((p) => Point(p.x * scale, p.y * scale)).toList();
  }

  // ---------------------------------------------------------------------------
  // Moore‑Neighbor boundary tracing
  // Returns a list of contours (each contour is a list of img.Point)
  // ---------------------------------------------------------------------------
  List<List<img.Point>> _traceContours(Uint8List binary, int w, int h) {
    final visited = Uint8List(w * h); // 0 = unvisited, 1 = visited
    final contours = <List<img.Point>>[];

    // 8‑neighbour offsets (clockwise starting from top-left)
    const dx = [-1, 0, 1, 1, 1, 0, -1, -1];
    const dy = [-1, -1, -1, 0, 1, 1, 1, 0];

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = y * w + x;
        if (binary[idx] == 0 || visited[idx] == 1) continue;

        // --- NEW: ensure this pixel is a boundary pixel ---
        bool isBoundary = false;
        for (int d = 0; d < 8; d++) {
          final nx = x + dx[d];
          final ny = y + dy[d];
          if (nx >= 0 &&
              nx < w &&
              ny >= 0 &&
              ny < h &&
              binary[ny * w + nx] == 0) {
            isBoundary = true;
            break;
          }
        }
        if (!isBoundary) continue;

        // Start a new contour
        final contour = <img.Point>[];
        int startX = x, startY = y;
        int curDir = 0; // initial search direction

        // Find first boundary pixel (Moore step)
        int cx = x, cy = y;
        bool found = false;

        // Find an initial boundary pixel (the current pixel may be inside the blob)
        // We'll use a simple approach: start from (x,y) and search for the first boundary pixel
        // by checking if any neighbour is 0; if so, (cx,cy) is a boundary pixel.
        // If not, we need to step to a boundary. This simplified Moore tracer works
        // if the starting pixel is already on the boundary. We'll adjust later.

        // Set current pixel as boundary start
        contour.add(img.Point(cx, cy));
        visited[cx + cy * w] = 1;

        // Find the next pixel clockwise
        int nextDir = 6; // start searching from the right neighbour (clockwise)
        int count = 0;
        do {
          int nx, ny;
          // Try to find next boundary pixel
          bool moved = false;
          for (int i = 0; i < 8; i++) {
            int dir = (nextDir + i) % 8;
            nx = cx + dx[dir];
            ny = cy + dy[dir];
            if (nx >= 0 &&
                nx < w &&
                ny >= 0 &&
                ny < h &&
                binary[ny * w + nx] != 0) {
              // Move to this pixel
              cx = nx;
              cy = ny;
              nextDir = (dir + 6) % 8; // set search direction for next step
              moved = true;
              break;
            }
          }
          if (!moved) break;
          if (cx == startX && cy == startY) break; // back to start
          contour.add(img.Point(cx, cy));
          visited[cx + cy * w] = 1;
          count++;
          if (count > w * h * 2) break; // safety
        } while (true);

        if (contour.isNotEmpty) {
          contours.add(contour);
        }
        // Mark all interior points as visited (simple flood fill from the first interior pixel)
        // This prevents re‑tracing the same blob. However, Moore tracer only traces outer boundary.
        // We'll just rely on visited array for boundary pixels, but we also need to mark all interior.
        // For now, we'll do a quick flood-fill from a pixel inside the contour.
        // Find a pixel inside (e.g., right of the start point)
        int insideX = startX + 1;
        if (insideX < w && binary[startY * w + insideX] != 0) {
          _floodFill(binary, visited, insideX, startY, w, h);
        }
      }
    }
    return contours;
  }

  void _floodFill(
    Uint8List binary,
    Uint8List visited,
    int startX,
    int startY,
    int w,
    int h,
  ) {
    final queue = Queue<(int, int)>();
    queue.add((startX, startY));

    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();

      // bounds check
      if (x < 0 || x >= w || y < 0 || y >= h) continue;

      final idx = y * w + x;
      if (binary[idx] == 0 || visited[idx] == 1) continue;

      visited[idx] = 1;

      // push 4‑neighbours (you can also use 8‑neighbour if desired)
      queue.add((x + 1, y));
      queue.add((x - 1, y));
      queue.add((x, y + 1));
      queue.add((x, y - 1));
    }
  }

  // ---------------------------------------------------------------------------
  // Pick the contour with the largest area (shoelace)
  // ---------------------------------------------------------------------------
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

  // ---------------------------------------------------------------------------
  // Fallback: simple box corners
  // ---------------------------------------------------------------------------
  List<Point> _boxToPolygon(
    double xMin,
    double yMin,
    double xMax,
    double yMax,
  ) {
    return [
      Point(xMin, yMin),
      Point(xMax, yMin),
      Point(xMax, yMax),
      Point(xMin, yMax),
    ];
  }
}

// ---------------------------------------------------------------------------
// Internal detection box structure (enhanced)
// ---------------------------------------------------------------------------
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
