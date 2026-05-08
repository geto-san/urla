import 'package:flutter/material.dart';
import 'package:urla/core/engine/braking_horizon_engine.dart';
import 'package:urla/core/engine/kalman_lane_tracker.dart';
import 'package:urla/core/engine/obstacle_engine.dart';
import 'package:urla/core/engine/oncoming_traffic_engine.dart';
import 'package:urla/core/engine/road_behavior_engine.dart';
import 'package:urla/core/engine/virtual_lane_generator.dart';
import 'package:urla/core/services/haptic_service.dart';
import 'package:urla/core/services/output_coordinator.dart';
import 'package:urla/core/services/tts_service.dart';
import 'package:urla/core/sources/camera_frame_source.dart';
import 'package:urla/data/runtime/repositories/driving_repo_impl.dart';
import 'package:urla/data/runtime/repositories/geo_repo_impl.dart';
import 'package:urla/data/runtime/repositories/lane_repo_impl.dart';
import 'package:urla/data/runtime/repositories/road_repo_impl.dart';
import 'package:uuid/uuid.dart';
import 'core/services/frame_processor.dart';
import 'core/services/geo_service.dart';
import 'core/services/tflite_service.dart';
import 'core/utils/camera_calibration.dart';
import 'core/engine/lane_engine.dart';
import 'core/engine/steering_engine.dart';
import 'core/engine/steering_temporal_engine.dart';
import 'data/database/app_database.dart';
import 'features/camera/viewmodel/camera_viewmodel.dart';
import 'features/home/home_screen.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── App entry point ──────────────────────────────────────────────────────

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _requestPermissions();

  final appDatabase = AppDatabase();
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver(appDatabase));

  runApp(
    MaterialApp(
      title: 'URLA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: HomeScreen(database: appDatabase),
    ),
  );
}

// ─── AppStarter ───────────────────────────────────────────────────────────
//
// Two-phase initialization:
//
//   Phase 1 — initServices(db)
//     Called at HomeScreen build. Builds all engines, repos, TFLite, GPS.
//     Does NOT touch the camera. Returns an AppServices bundle.
//
//   Phase 2 — buildViewModel(services, cameraSource)
//     Called when the user navigates to the Dashboard.
//     Initializes and wires the camera source.
//
// This keeps the camera hardware released until actually needed.
// ─────────────────────────────────────────────────────────────────────────

class AppServices {
  final TFLiteService tfliteService;
  final LaneEngine laneEngine;
  final DynamicCalibration calibration;
  final FrameProcessor frameProcessor;
  final OutputCoordinator outputCoordinator;

  const AppServices({
    required this.tfliteService,
    required this.laneEngine,
    required this.calibration,
    required this.frameProcessor,
    required this.outputCoordinator,
  });
}

class AppStarter {
  // Exposed for ImageTestScreen access without re-initializing.
  static AppServices? _services;
  static AppServices get services {
    assert(_services != null, 'Call initServices() first');
    return _services!;
  }

  // ── Phase 1: everything except camera ────────────────────────────────────
  static Future<AppServices> initServices(AppDatabase db) async {
    if (_services != null) return _services!;

    final sessionId = const Uuid().v4();

    // Calibration (tune focal lengths for your device)
    final calibration = DynamicCalibration(
      focalX: 800,
      focalY: 800,
      principalX: 640,
      principalY: 480,
      cameraHeight: 1.2,
    );

    // TFLite — loads model into isolate (no camera needed)
    final tfliteService = TFLiteService();
    await tfliteService.loadModel();

    // Output services
    final ttsService    = TtsService();
    final hapticService = HapticService();
    await ttsService.initialize();
    await hapticService.initialize();
    final outputCoordinator = OutputCoordinator(ttsService, hapticService);

    // Repositories
    final laneRepository    = LaneRepositoryImpl(db);
    final roadRepository    = RoadRepositoryImpl(db);
    final geoRepository     = GeoRepositoryImpl(db);
    final drivingRepository = DrivingRepositoryImpl(db);

    // Engines
    final laneEngine         = LaneEngine(calibration);
    final obstacleEngine     = ObstacleEngine();
    final trafficEngine      = OncomingTrafficEngine(calibration);
    final steeringEngine     = SteeringIntentEngine(trafficEngine);
    final temporalSteering   = TemporalSteeringEngine(steeringEngine);
    final kalmanTracker      = KalmanLaneTracker();
    final virtualGenerator   = VirtualLaneGenerator(kalmanTracker);
    final brakingEngine      = BrakingHorizonEngine(calibration);
    final behaviourEngine    = RoadBehaviourEngine();

    // Frame processor
    final frameProcessor = FrameProcessor(
      laneEngine,
      laneRepository,
      roadRepository,
      geoRepository,
      drivingRepository,
      GeoService(),
      calibration,
      sessionId,
      obstacleEngine,
      trafficEngine,
      temporalSteering,
      kalmanTracker,
      virtualGenerator,
      brakingEngine,
      behaviourEngine,
    );
    frameProcessor.startGeoUpdates();

    _services = AppServices(
      tfliteService:     tfliteService,
      laneEngine:        laneEngine,
      calibration:       calibration,
      frameProcessor:    frameProcessor,
      outputCoordinator: outputCoordinator,
    );
    return _services!;
  }

  // ── Phase 2: build ViewModel with camera ─────────────────────────────────
  //
  // Called the first time the user presses "Camera (Live)".
  // CameraFrameSource is created fresh here — initialize() is NOT called yet.
  // The ViewModel calls initialize() + start() inside its own start() method
  // which is triggered by DashboardScreen.initState().
  static CameraViewModel buildLiveViewModel(AppServices services) {
    final cameraSource = CameraFrameSource();

    return CameraViewModel(
      source:            cameraSource,
      tflite:            services.tfliteService,
      processor:         services.frameProcessor,
      outputCoordinator: services.outputCoordinator,
      geoStream:         services.frameProcessor.geoStream,
    );
  }
}

// ─── Permissions ──────────────────────────────────────────────────────────

Future<void> _requestPermissions() async {
  await [Permission.camera, Permission.location].request();
  if (!await Permission.camera.isGranted) {
    throw Exception('Camera permission denied');
  }
}

// ─── Database lifecycle ───────────────────────────────────────────────────

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final AppDatabase db;
  _AppLifecycleObserver(this.db);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) db.close();
  }
}
