import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../../core/ml/yolo_decoder.dart';
import '../../data/runtime/models/detection_model.dart';
import '../../data/runtime/models/frame_processing_result.dart';
import '../camera/view/lane_overly_painter.dart';

class SimpleTestScreen extends StatefulWidget {
  const SimpleTestScreen({super.key});

  @override
  State<SimpleTestScreen> createState() => _SimpleTestScreenState();
}

class _SimpleTestScreenState extends State<SimpleTestScreen> {
  final picker = ImagePicker();
  Interpreter? interpreter;
  final decoder = YoloSegDecoder();

  File? imageFile;
  List<DetectionModel>? detections;
  Size? imageNaturalSize;
  bool loading = true;
  bool processing = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      final raw = await DefaultAssetBundle.of(context)
          .load('assets/models/yolov8_lane_seg.tflite');
      final bytes = raw.buffer.asUint8List();
      final interp = Interpreter.fromBuffer(bytes);
      interp.allocateTensors();
      interpreter = interp;
      setState(() => loading = false);
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Failed to load model: $e';
      });
    }
  }

  Future<void> pickImage() async {
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() {
      processing = true;
      error = null;
      detections = null;
      imageFile = File(file.path);
    });

    try {
      final bytes = await File(file.path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) throw Exception('Failed to decode image');

      // Save natural size BEFORE any resizing
      imageNaturalSize = Size(decoded.width.toDouble(), decoded.height.toDouble());

      // Letterbox preprocessing
      final (tensor, scale, dx, dy) = _preprocessLetterbox(decoded);
      final shaped = tensor.reshape([1, 640, 640, 3]);

      // Output buffers
      final detOut = Float32List(39 * 8400);
      final maskOut = Float32List(160 * 160 * 32);

      interpreter!.run(shaped, {0: detOut, 1: maskOut});

      // Tell decoder how to un‑transform
      decoder.setPreprocessParams(scale, dx, dy);

      final dets = decoder.decode([detOut, maskOut], 0.4);
      setState(() {
        detections = dets;
        processing = false;
      });
    } catch (e) {
      setState(() {
        processing = false;
        error = e.toString();
      });
    }
  }

  (Float32List, double, double, double) _preprocessLetterbox(img.Image original) {
    const int inputSize = 640;
    final scale = (inputSize / original.width)
        .clamp(0, inputSize / original.height)
        .toDouble();
    final newW = (original.width * scale).round();
    final newH = (original.height * scale).round();

    final resized = img.copyResize(original, width: newW, height: newH,
        interpolation: img.Interpolation.linear);

    final canvas = img.Image(width: inputSize, height: inputSize);
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));

    final dx = (inputSize - newW) ~/ 2;
    final dy = (inputSize - newH) ~/ 2;
    img.compositeImage(canvas, resized, dstX: dx, dstY: dy);

    final tensor = Float32List(inputSize * inputSize * 3);
    int idx = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = canvas.getPixel(x, y);
        tensor[idx++] = pixel.r / 255.0;
        tensor[idx++] = pixel.g / 255.0;
        tensor[idx++] = pixel.b / 255.0;
      }
    }

    return (tensor, scale, dx.toDouble(), dy.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error != null && imageFile == null) {
      return Scaffold(
        body: Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
      );
    }

    // Capture local variables to avoid null‑check operator later
    final file = imageFile;
    final dets = detections;
    final naturalSize = imageNaturalSize;

    return Scaffold(
      appBar: AppBar(title: const Text('Simple Test')),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImage,
        child: const Icon(Icons.image),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: file != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(file, fit: BoxFit.contain),
                      if (dets != null)
                        CustomPaint(
                          painter: LaneOverlayPainter(
                            FrameProcessingResult(detections: dets),
                            sourceImageSize: naturalSize,
                          ),
                        ),
                      if (processing)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  )
                : const Center(child: Text('Pick an image')),
          ),
          Expanded(
            flex: 2,
            child: _buildDebug(dets),
          ),
        ],
      ),
    );
  }

  Widget _buildDebug(List<DetectionModel>? dets) {
    if (error != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (dets == null) {
      return const Center(child: Text('No detections'));
    }
    final byClass = <String, int>{};
    for (final d in dets) {
      byClass[d.className] = (byClass[d.className] ?? 0) + 1;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontFamily: 'monospace'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total detections: ${dets.length}'),
            ...byClass.entries.map((e) => Text('  ${e.key}: ${e.value}')),
            ...dets.take(5).map((d) => Text(
                '${d.className} ${(d.confidence * 100).toStringAsFixed(0)}%')),
          ],
        ),
      ),
    );
  }
}