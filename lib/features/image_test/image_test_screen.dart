import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/domain/models/frame_data.dart';
import '../../core/sources/image_frame_source.dart';
import '../../core/services/tflite_service.dart';
import '../../core/engine/lane_engine.dart';
import '../../core/utils/camera_calibration.dart';
import '../../data/runtime/models/detection_model.dart';
import '../../data/runtime/models/lane_model.dart';
import '../../data/runtime/models/frame_processing_result.dart';
import '../camera/view/lane_overly_painter.dart';

class ImageTestScreen extends StatefulWidget {
  final TFLiteService tfliteService;
  final LaneEngine laneEngine;

  const ImageTestScreen({
    super.key,
    required this.tfliteService,
    required this.laneEngine,
  });

  @override
  State<ImageTestScreen> createState() => _ImageTestScreenState();
}

class _ImageTestScreenState extends State<ImageTestScreen> {
  final ImageFrameSource _source = ImageFrameSource();
  StreamSubscription<FrameData>? _subscription;

  Uint8List? _rawImageBytes;

  /// Natural pixel size of the picked image — needed for overlay alignment.
  Size? _imageNaturalSize;

  List<DetectionModel>? _detections;
  LaneModel? _lane;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _source.frameStream.listen(_onFrame);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _source.dispose();
    super.dispose();
  }

  Future<void> _onFrame(FrameData frame) async {
    if (_processing) return;
    _processing = true;

    // Store the raw bytes for display AND remember the natural pixel dimensions.
    // frame.width/height are the decoded image dimensions before any resize.
    setState(() {
      _rawImageBytes    = _source.lastRawBytes;
      _imageNaturalSize = Size(frame.width.toDouble(), frame.height.toDouble());
      _error            = null;
    });

    try {
      final detections = await widget.tfliteService.predict(frame);

      // Use a local calibration for the image test — no live GPS available.
      final calibration = DynamicCalibration(
        focalX:       800,
        focalY:       800,
        principalX:   640,
        principalY:   480,
        cameraHeight: 1.2,
      );
      final lane = widget.laneEngine.buildLane(detections);

      if (!mounted) return;
      setState(() {
        _detections = detections;
        _lane       = lane;
        _processing = false;
      });
    } catch (e, stack) {
      debugPrint('ImageTestScreen inference error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error      = e.toString();
      });
    }
  }

  void _pickImage() => _source.pickImage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Image Test')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildImageSection(),
          ),
          Expanded(
            flex: 2,
            child: _buildDebugInfo(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.image),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_rawImageBytes == null) {
      return const Center(
        child: Text('Pick an image', style: TextStyle(color: Colors.white54)),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Display the image with contain fitting (may have black bars)
        Image.memory(
          _rawImageBytes!,
          fit: BoxFit.contain,
        ),

        // Overlay — pass the natural image size so the painter can compute
        // the exact BoxFit.contain destination rect and align correctly.
        if (_detections != null)
          CustomPaint(
            painter: LaneOverlayPainter(
              FrameProcessingResult(
                lane:       _lane,
                detections: _detections!,
              ),
              // ← Key fix: tells the painter the source image dimensions
              // so it maps model coords to the letterboxed image area,
              // not the full canvas.
              sourceImageSize: _imageNaturalSize,
            ),
          ),
      ],
    );
  }

  Widget _buildDebugInfo() {
    if (_processing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
        ),
      );
    }
    if (_detections == null) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }

    // Group detections by class for easier reading
    final byClass = <String, List<DetectionModel>>{};
    for (final d in _detections!) {
      byClass.putIfAbsent(d.className, () => []).add(d);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: DefaultTextStyle(
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontFamily: 'monospace',
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detections: ${_detections!.length}'),
            ...byClass.entries.map((e) =>
              Text('  ${e.key}: ${e.value.length} '
                   '(best: ${(e.value.map((d) => d.confidence).reduce((a, b) => a > b ? a : b) * 100).toStringAsFixed(0)}%)')),
            const SizedBox(height: 6),
            if (_lane != null) ...[
              Text('Lane type: ${_lane!.type.name}'),
              Text('Lane width:   ${_lane!.laneWidth.toStringAsFixed(2)} m'),
              Text('Curvature:    ${_lane!.curvature.toStringAsFixed(4)} m⁻¹'),
              Text('Drift score:  ${_lane!.driftScore.toStringAsFixed(3)} m'),
              Text('Confidence:   ${(_lane!.confidence * 100).toStringAsFixed(0)}%'),
              Text('Center pts:   ${_lane!.centerLine.length}'),
              Text('Left pts:     ${_lane!.leftBoundary.length}'),
              Text('Right pts:    ${_lane!.rightBoundary.length}'),
            ],
          ],
        ),
      ),
    );
  }
}