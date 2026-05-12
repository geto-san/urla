// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_min/return_code.dart';
// import 'package:flutter/material.dart';
// import 'package:image/image.dart' as img;
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';

// import '../../core/engine/lane_engine.dart';
// import '../../core/services/tflite_service.dart';
// import '../../data/domain/models/frame_data.dart';
// import '../../data/runtime/models/detection_model.dart';
// import '../../data/runtime/models/frame_processing_result.dart';
// import '../camera/view/lane_overly_painter.dart';

// // ---------------------------------------------------------------------------
// // VideoTestScreen
// //
// // Picks a video, extracts frames at [_targetFps] via ffmpeg, then runs each
// // frame through TFLite + LaneEngine and renders the overlay — exactly like
// // the live camera but on pre-recorded footage.
// // ---------------------------------------------------------------------------
// class VideoTestScreen extends StatefulWidget {
//   final TFLiteService tfliteService;
//   final LaneEngine    laneEngine;

//   const VideoTestScreen({
//     super.key,
//     required this.tfliteService,
//     required this.laneEngine,
//   });

//   @override
//   State<VideoTestScreen> createState() => _VideoTestScreenState();
// }

// class _VideoTestScreenState extends State<VideoTestScreen> {
//   // ── State ─────────────────────────────────────────────────────────────────

//   List<File> _frames       = [];
//   int        _currentIndex = 0;

//   Uint8List?             _displayBytes;
//   Size?                  _frameSize;
//   FrameProcessingResult? _result;

//   bool    _extracting = false;
//   bool    _inferring  = false;
//   Timer?  _playTimer;

//   bool get _isPlaying => _playTimer != null;

//   static const int _targetFps = 5;

//   String? _statusMessage;
//   String? _error;

//   Directory? _framesDir;

//   // ── Init / dispose ────────────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     _initFramesDir();
//   }

//   Future<void> _initFramesDir() async {
//     final tmp  = await getTemporaryDirectory();
//     _framesDir = Directory('${tmp.path}/urla_video_frames');
//     if (_framesDir!.existsSync()) _framesDir!.deleteSync(recursive: true);
//     _framesDir!.createSync();
//   }

//   @override
//   void dispose() {
//     _playTimer?.cancel();
//     super.dispose();
//   }

//   // ── Video picking & extraction ────────────────────────────────────────────

//   Future<void> _pickAndExtract() async {
//     final picker = ImagePicker();
//     final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
//     if (file == null) return;

//     // Stop playback before clearing state.
//     if (_isPlaying) _stopPlayback();

//     setState(() {
//       _extracting    = true;
//       _frames        = [];
//       _currentIndex  = 0;
//       _displayBytes  = null;
//       _result        = null;
//       _statusMessage = 'Extracting frames at $_targetFps fps…';
//       _error         = null;
//     });

//     if (_framesDir != null && _framesDir!.existsSync()) {
//       _framesDir!.deleteSync(recursive: true);
//       _framesDir!.createSync();
//     }

//     final outPattern = '${_framesDir!.path}/frame_%04d.jpg';
//     final cmd =
//         '-i "${file.path}" -vf "fps=$_targetFps,scale=\'min(720,iw)\':-2" '
//         '-q:v 2 "$outPattern"';

//     final session = await FFmpegKit.execute(cmd);
//     final rc      = await session.getReturnCode();

//     if (!ReturnCode.isSuccess(rc)) {
//       if (!mounted) return;
//       final logs = await session.getLogsAsString();
//       setState(() {
//         _extracting    = false;
//         _error         = 'ffmpeg failed:\n$logs';
//         _statusMessage = null;
//       });
//       return;
//     }

//     final files = _framesDir!
//         .listSync()
//         .whereType<File>()
//         .where((f) => f.path.endsWith('.jpg'))
//         .toList()
//       ..sort((a, b) => a.path.compareTo(b.path));

//     if (!mounted) return;
//     setState(() {
//       _frames        = files;
//       _extracting    = false;
//       _statusMessage = '${files.length} frames extracted';
//     });

//     if (files.isNotEmpty) await _showFrame(0);
//   }

//   // ── Frame display & inference ─────────────────────────────────────────────

//   Future<void> _showFrame(int index) async {
//     if (index < 0 || index >= _frames.length) return;

//     // Guard: don't stack inference calls during rapid scrubbing / playback.
//     // We update the index immediately so the scrubber feels responsive, then
//     // run inference for the frame that was current when inference finishes.
//     if (!mounted) return;
//     setState(() {
//       _currentIndex = index;
//       _result       = null; // clear stale result while inferring
//     });

//     final bytes   = await _frames[index].readAsBytes();
//     final decoded = img.decodeJpg(bytes);
//     if (decoded == null || !mounted) return;

//     setState(() {
//       _displayBytes = bytes;
//       _frameSize    = Size(decoded.width.toDouble(), decoded.height.toDouble());
//     });

//     await _runInference(decoded);
//   }

//   Future<void> _runInference(img.Image decoded) async {
//     // Skip if another inference is already in flight (e.g. fast scrubbing).
//     if (_inferring) return;
//     _inferring = true;

//     try {
//       final rgbBytes = Uint8List.fromList(
//         decoded.getBytes(order: img.ChannelOrder.rgb),
//       );

//       final frame = FrameData(
//         bytes:  rgbBytes,
//         width:  decoded.width,
//         height: decoded.height,
//       );

//       final result = await widget.tfliteService.predict(frame);

//       // dropped:true means the service was busy — skip this frame silently.
//       // This can happen during fast playback; the next frame will succeed.
//       if (result.dropped || !mounted) return;

//       final lane = widget.laneEngine.buildLane(result.detections);

//       if (!mounted) return;
//       setState(() {
//         _result = FrameProcessingResult(
//           lane:        lane,
//           detections:  result.detections,
//           frameWidth:  decoded.width,
//           frameHeight: decoded.height,
//         );
//       });
//     } catch (e, st) {
//       debugPrint('VideoTestScreen inference error: $e\n$st');
//       if (!mounted) return;
//       setState(() => _error = e.toString());
//     } finally {
//       _inferring = false;
//     }
//   }

//   // ── Playback controls ─────────────────────────────────────────────────────

//   void _togglePlay() {
//     if (_isPlaying) {
//       _stopPlayback();
//     } else {
//       _startPlayback();
//     }
//     setState(() {});
//   }

//   void _startPlayback() {
//     _playTimer = Timer.periodic(
//       Duration(milliseconds: (1000 / _targetFps).round()),
//       (_) async {
//         final next = _currentIndex + 1;
//         if (next >= _frames.length) {
//           _stopPlayback();
//           if (mounted) setState(() {});
//           return;
//         }
//         await _showFrame(next);
//       },
//     );
//   }

//   void _stopPlayback() {
//     _playTimer?.cancel();
//     _playTimer = null;
//   }

//   void _stepFrame(int delta) {
//     if (_isPlaying) {
//       _stopPlayback();
//       setState(() {});
//     }
//     _showFrame((_currentIndex + delta).clamp(0, _frames.length - 1));
//   }

//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       appBar: AppBar(
//         title: const Text('Video Test'),
//         actions: [
//           IconButton(
//             icon:    const Icon(Icons.video_library),
//             tooltip: 'Pick video',
//             onPressed: _extracting ? null : _pickAndExtract,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(flex: 3, child: _buildFrameSection()),
//           _buildControls(),
//           Expanded(flex: 2, child: _buildDebugInfo()),
//         ],
//       ),
//     );
//   }

//   Widget _buildFrameSection() {
//     if (_extracting) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const CircularProgressIndicator(),
//             const SizedBox(height: 12),
//             Text(
//               _statusMessage ?? '',
//               style: const TextStyle(color: Colors.white70),
//             ),
//           ],
//         ),
//       );
//     }

//     if (_displayBytes == null) {
//       return Center(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.video_library, size: 64, color: Colors.white24),
//             const SizedBox(height: 12),
//             const Text(
//               'Pick a video to begin',
//               style: TextStyle(color: Colors.white54),
//             ),
//             if (_error != null) ...[
//               const SizedBox(height: 8),
//               Text(
//                 _error!,
//                 style: const TextStyle(color: Colors.red, fontSize: 11),
//               ),
//             ],
//           ],
//         ),
//       );
//     }

//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         Image.memory(_displayBytes!, fit: BoxFit.contain),
//         if (_result != null)
//           CustomPaint(
//             painter: LaneOverlayPainter(
//               _result,
//               sourceImageSize: _frameSize,
//               debugMode:       true,
//             ),
//           ),
//         // Spinner in corner while inferring (non-blocking)
//         if (_inferring)
//           const Positioned(
//             top: 8, right: 8,
//             child: SizedBox(
//               width: 20, height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildControls() {
//     if (_frames.isEmpty) return const SizedBox.shrink();

//     return Container(
//       color: Colors.grey[900],
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Slider(
//             value:     _currentIndex.toDouble(),
//             min:       0,
//             max:       (_frames.length - 1).toDouble(),
//             divisions: _frames.length - 1,
//             label:     'Frame $_currentIndex',
//             onChanged: (v) {
//               if (_isPlaying) {
//                 _stopPlayback();
//                 setState(() {});
//               }
//               _showFrame(v.round());
//             },
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               IconButton(
//                 icon:    const Icon(Icons.skip_previous, color: Colors.white),
//                 onPressed: () => _stepFrame(-1),
//               ),
//               IconButton(
//                 icon: Icon(
//                   _isPlaying ? Icons.pause : Icons.play_arrow,
//                   color: Colors.white,
//                   size: 32,
//                 ),
//                 onPressed: _togglePlay,
//               ),
//               IconButton(
//                 icon:    const Icon(Icons.skip_next, color: Colors.white),
//                 onPressed: () => _stepFrame(1),
//               ),
//               const SizedBox(width: 16),
//               Text(
//                 'Frame ${_currentIndex + 1} / ${_frames.length}',
//                 style: const TextStyle(color: Colors.white70, fontSize: 12),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDebugInfo() {
//     if (_error != null && _displayBytes != null) {
//       return Padding(
//         padding: const EdgeInsets.all(8),
//         child: Text(
//           _error!,
//           style: const TextStyle(color: Colors.red, fontSize: 11),
//         ),
//       );
//     }

//     final result = _result;
//     if (result == null) {
//       return const Center(
//         child: Text(
//           'No inference result',
//           style: TextStyle(color: Colors.white38),
//         ),
//       );
//     }

//     final lane = result.lane;
//     final dets = result.detections;

//     final byClass = <String, List<DetectionModel>>{};
//     for (final d in dets) {
//       byClass.putIfAbsent(d.className, () => []).add(d);
//     }

//     final lines = <String>[
//       'Frame size: ${result.frameWidth}×${result.frameHeight}',
//       'Detections: ${dets.length}',
//       ...byClass.entries.map((e) {
//         final best = e.value
//             .map((d) => d.confidence)
//             .reduce((a, b) => a > b ? a : b);
//         return '  ${e.key}: ${e.value.length}  '
//             '(best ${(best * 100).toStringAsFixed(0)}%)';
//       }),
//       if (lane != null) ...[
//         '',
//         'Lane type:   ${lane.type.name}',
//         'Width:       ${lane.laneWidth.toStringAsFixed(2)} m',
//         'Curvature:   ${lane.curvature.toStringAsFixed(4)} m⁻¹',
//         'Drift:       ${lane.driftScore.toStringAsFixed(3)} m',
//         'Confidence:  ${(lane.confidence * 100).toStringAsFixed(0)}%',
//         'Center pts:  ${lane.centerLine.length}',
//       ] else
//         'Lane: not detected',
//     ];

//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(8),
//       child: DefaultTextStyle(
//         style: const TextStyle(
//           color:      Colors.greenAccent,
//           fontSize:   12,
//           fontFamily: 'monospace',
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: lines.map((s) => Text(s)).toList(),
//         ),
//       ),
//     );
//   }
// }