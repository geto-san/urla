import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:urla/data/runtime/models/frame_processing_result.dart';
import 'package:urla/features/camera/view/lane_overly_painter.dart';
import '../viewmodel/camera_viewmodel.dart';

class CameraScreen extends StatefulWidget {
  final CameraViewModel viewModel;

  const CameraScreen({Key? key, required this.viewModel}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: ValueListenableBuilder<CameraController?>(
        valueListenable: widget.viewModel.controllerNotifier, // we'll add it
        builder: (context, controller, child) {
          if (controller == null || !controller.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Stack(
            children: [
              // Live camera preview
              CameraPreview(controller),

              // Overlay painter
              Positioned.fill(
                child: ValueListenableBuilder<FrameProcessingResult?>(
                  valueListenable: widget.viewModel.overlayData,
                  builder: (context, result, child) {
                    return CustomPaint(
                      painter: LaneOverlayPainter(result),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}