import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/engine/lane_engine.dart';
import '../../core/services/tflite_service.dart';
import '../../core/sources/image_frame_source.dart';
import '../../data/domain/models/frame_data.dart';
import '../../data/runtime/models/detection_model.dart';
import '../../data/runtime/models/frame_processing_result.dart';
import '../../data/runtime/models/lane_model.dart';
import '../camera/view/lane_overly_painter.dart';

class ImageTestScreen extends StatefulWidget {
  final TFLiteService tfliteService;
  final LaneEngine    laneEngine;

  const ImageTestScreen({
    super.key,
    required this.tfliteService,
    required this.laneEngine,
  });

  @override
  State<ImageTestScreen> createState() => _ImageTestScreenState();
}

class _ImageTestScreenState extends State<ImageTestScreen> {
  final _source = ImageFrameSource();
  StreamSubscription<FrameData>? _subscription;

  Uint8List? _rawImageBytes;

  /// Natural pixel size of the picked image — needed for overlay alignment.
  Size? _imageNaturalSize;

  List<DetectionModel>? _detections;
  LaneModel?            _lane;
  bool                  _processing = false;
  String?               _error;

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

  // ── Inference ─────────────────────────────────────────────────────────────

  Future<void> _onFrame(FrameData frame) async {
    if (_processing) return;
    _processing = true;

    if (!mounted) return;
    setState(() {
      _rawImageBytes    = _source.lastRawBytes;
      _imageNaturalSize = Size(frame.width.toDouble(), frame.height.toDouble());
      _error            = null;
    });

    try {
      final result = await widget.tfliteService.predict(frame);

      // predict() returns dropped:true only when TFLiteService is busy.
      // In the image test we are the sole caller, so this should not happen —
      // but guard it anyway to avoid a null-detections state.
      if (result.dropped) {
        if (!mounted) return;
        setState(() => _processing = false);
        return;
      }

      final lane = widget.laneEngine.buildLane(result.detections);

      if (!mounted) return;
      setState(() {
        _detections = result.detections;
        _lane       = lane;
        _processing = false;
      });
    } catch (e, st) {
      debugPrint('ImageTestScreen inference error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error      = e.toString();
      });
    }
  }

  void _pickImage() => _source.pickImage();

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Image Test')),
      body: Column(
        children: [
          Expanded(flex: 3, child: _buildImageSection()),
          Expanded(flex: 2, child: _buildDebugInfo()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _processing ? null : _pickImage,
        child: _processing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.image),
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
        Image.memory(_rawImageBytes!, fit: BoxFit.contain),
        if (_detections != null)
          CustomPaint(
            painter: LaneOverlayPainter(
              FrameProcessingResult(
                lane:       _lane,
                detections: _detections!,
              ),
              // Tells the painter the source image dimensions so it maps model
              // coords to the letterboxed image area, not the full canvas.
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
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.red, fontSize: 11),
          ),
        ),
      );
    }
    if (_detections == null) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.white54)),
      );
    }

    final byClass = _groupByClass(_detections!);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: _DebugText(
        children: [
          'Detections: ${_detections!.length}',
          ...byClass.entries.map((e) {
            final best = _bestConf(e.value);
            return '  ${e.key}: ${e.value.length}  '
                '(best: ${(best * 100).toStringAsFixed(0)}%)';
          }),
          if (_lane != null) ...[
            '',
            'Lane type:    ${_lane!.type.name}',
            'Lane width:   ${_lane!.laneWidth.toStringAsFixed(2)} m',
            'Curvature:    ${_lane!.curvature.toStringAsFixed(4)} m⁻¹',
            'Drift score:  ${_lane!.driftScore.toStringAsFixed(3)} m',
            'Confidence:   ${(_lane!.confidence * 100).toStringAsFixed(0)}%',
            'Center pts:   ${_lane!.centerLine.length}',
            'Left pts:     ${_lane!.leftBoundary.length}',
            'Right pts:    ${_lane!.rightBoundary.length}',
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Map<String, List<DetectionModel>> _groupByClass(List<DetectionModel> dets) {
    final map = <String, List<DetectionModel>>{};
    for (final d in dets) {
      map.putIfAbsent(d.className, () => []).add(d);
    }
    return map;
  }

  double _bestConf(List<DetectionModel> list) =>
      list.map((d) => d.confidence).reduce((a, b) => a > b ? a : b);
}

// ── Shared monospace debug widget ─────────────────────────────────────────

class _DebugText extends StatelessWidget {
  final List<String> children;
  const _DebugText({required this.children});

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        color:      Colors.greenAccent,
        fontSize:   12,
        fontFamily: 'monospace',
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children.map((s) => Text(s)).toList(),
      ),
    );
  }
}