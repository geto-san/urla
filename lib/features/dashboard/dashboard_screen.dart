import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:urla/data/runtime/models/frame_processing_result.dart';
import '../camera/viewmodel/camera_viewmodel.dart';
import 'widgets/debug_panel.dart';
import 'widgets/map_panel.dart';
import '../camera/view/lane_overly_painter.dart';

class DashboardScreen extends StatefulWidget {
  final CameraViewModel viewModel;
  final bool debugMode;

  const DashboardScreen({super.key, required this.viewModel, required this.debugMode});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.start();   // 🆕
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Camera preview with overlay
          Expanded(
            flex: 3,
            child: _buildCameraSection(),
          ),
          // Bottom panel (debug or map)
          Expanded(
            flex: 2,
            child: _buildBottomPanel(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => widget.viewModel.toggleMap(),
        child: ValueListenableBuilder<bool>(
          valueListenable: widget.viewModel.showMap,
          builder: (_, showMap, __) => Icon(showMap ? Icons.text_snippet : Icons.map),
        ),
      ),
    );
  }

  Widget _buildCameraSection() {
    return ValueListenableBuilder<CameraController?>(
      valueListenable: widget.viewModel.controllerNotifier,
      builder: (context, controller, child) {
        if (controller == null || !controller.value.isInitialized) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            // BoxFit.contain keeps the full frame visible with black bars.
            // This matches the painter's coordinate mapping exactly.
            OverflowBox(
              alignment: Alignment.center,
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: CameraPreview(controller),
              ),
            ),
            Positioned.fill(
              child: ValueListenableBuilder<FrameProcessingResult?>(
                valueListenable: widget.viewModel.overlayData,
                builder: (context, result, child) {
                  return CustomPaint(
                    painter: LaneOverlayPainter(result, debugMode: widget.debugMode),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomPanel() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.viewModel.showMap,
      builder: (context, showMap, _) {
        if (showMap) {
          return MapPanel(geoNotifier: widget.viewModel.currentGeo);
        } else {
          return DebugPanel(overlayNotifier: widget.viewModel.overlayData, debugMode: widget.debugMode);
        }
      },
    );
  }
}