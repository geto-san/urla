import 'package:flutter/material.dart';
import 'package:urla/data/database/app_database.dart';
import 'package:urla/features/camera/viewmodel/camera_viewmodel.dart';
import 'package:urla/features/dashboard/dashboard_screen.dart';
import 'package:urla/features/image_test/image_test_screen.dart';
import 'package:urla/features/image_test/simple_test_screen.dart';
import 'package:urla/features/video_test/video_test_screen.dart';
import 'package:urla/main.dart' show AppStarter, AppServices;

class HomeScreen extends StatefulWidget {
  final AppDatabase database;
  const HomeScreen({super.key, required this.database});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Phase 1: services (no camera) — started immediately.
  late Future<AppServices> _servicesFuture;

  // Phase 2: live ViewModel — created lazily on first "Camera" press.
  CameraViewModel? _liveViewModel;

  bool _debugMode = true;

  @override
  void initState() {
    super.initState();
    // Phase 1: loads TFLite, engines, repos, GPS. Camera NOT opened.
    _servicesFuture = AppStarter.initServices(widget.database);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, size: 100, color: Colors.greenAccent),
            const SizedBox(height: 20),
            const Text(
              'URLA',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Unified Road & Lane Analyzer',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 40),
            SwitchListTile(
              title: const Text('Debug Overlay', style: TextStyle(color: Colors.white)),
              value: _debugMode,
              onChanged: (v) => setState(() => _debugMode = v),
            ),
            const SizedBox(height: 20),

            // ── Camera (live) ─────────────────────────────────────────────
            ElevatedButton.icon(
              icon: const Icon(Icons.camera),
              label: const Text('Camera (Live)'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
              onPressed: () async {
                print('[HomeScreen] Camera button pressed');
                final services = await _servicesFuture;
                print('[HomeScreen] Services ready');  
                if (!mounted) return;

                // Build ViewModel the first time — creates CameraFrameSource
                // but does NOT open the camera yet.
                _liveViewModel ??= AppStarter.buildLiveViewModel(services);

                 print('[HomeScreen] Navigating to Dashboard');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(
                      viewModel: _liveViewModel!,
                      debugMode: _debugMode,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),

            // ── Test with image ───────────────────────────────────────────
            // ElevatedButton.icon(
            //   icon: const Icon(Icons.image),
            //   label: const Text('Test with Image'),
            //   style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
            //   onPressed: () async {

            //     print('[HomeScreen] Test with Image button pressed');
            //     final services = await _servicesFuture;
            //     print('[HomeScreen] Services ready');  
            //     if (!mounted) return;

            //     // Stop live camera if running so TFLite interpreter is free.
            //     if (_liveViewModel != null) {
            //       await _liveViewModel!.stop();
            //     }

            //      print('[HomeScreen] Navigating to ImageTestScreen');
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (_) => ImageTestScreen(
            //           tfliteService: services.tfliteService,
            //           laneEngine:    services.laneEngine,
            //         ),
            //       ),
            //     );
            //   },
            // ),
          
            // ElevatedButton.icon(
            //   icon: const Icon(Icons.bug_report),
            //   label: const Text("Simple Test"),
            //   onPressed: () {
            //     Navigator.of(context).push(
            //       MaterialPageRoute(builder: (_) => const SimpleTestScreen()),
            //     );
            //   },
            // ),

            // const SizedBox(height: 10),

            // // ── Test with video ───────────────────────────────────────────
            // ElevatedButton.icon(
            //   icon: const Icon(Icons.video_library),
            //   label: const Text('Test with Video'),
            //   style: ElevatedButton.styleFrom(minimumSize: const Size(250, 50)),
            //   onPressed: () async {
            //     final services = await _servicesFuture;
            //     if (!mounted) return;

            //     // Stop live camera if running so TFLite interpreter is free.
            //     if (_liveViewModel != null) {
            //       await _liveViewModel!.stop();
            //     }

            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (_) => VideoTestScreen(
            //           tfliteService: services.tfliteService,
            //           laneEngine:    services.laneEngine,
            //         ),
            //       ),
            //     );
            //   },
            // ),
          
          ],
        ),
      ),
    );
  }
}
