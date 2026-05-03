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
import 'package:urla/data/runtime/repositories/driving_repo_impl.dart';
import 'package:urla/data/runtime/repositories/geo_repo_impl.dart';
import 'package:urla/data/runtime/repositories/lane_repo_impl.dart';
import 'package:urla/data/runtime/repositories/ml_repo_impl.dart';
import 'package:urla/data/runtime/repositories/road_repo_impl.dart';
import 'package:uuid/uuid.dart';
import 'app/app.dart';
import 'core/services/camera_services.dart';
import 'core/services/frame_processor.dart';
import 'core/services/geo_service.dart';
import 'core/services/tflite_service.dart';
import 'core/utils/camera_calibration.dart';
import 'core/engine/lane_engine.dart';
import 'core/engine/steering_engine.dart';
import 'core/engine/steering_temporal_engine.dart';
import 'data/database/app_database.dart';
import 'features/camera/viewmodel/camera_viewmodel.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestPermissions();

  final appDatabase = AppDatabase();
  WidgetsBinding.instance.addObserver(_AppLifecycleObserver(appDatabase));

  runApp(
    FutureBuilder<CameraViewModel>(
      future: _initializeApp(appDatabase),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('Initialization failed: ${snapshot.error}'),
              ),
            ),
          );
        }
        return URLAApp(viewModel: snapshot.data!);
      },
    ),
  );
}

Future<CameraViewModel> _initializeApp(AppDatabase db) async {
  final sessionId = const Uuid().v4();

  // 1. Calibration
  final calibration = DynamicCalibration(
    focalX: 800,
    focalY: 800,
    principalX: 640,
    principalY: 480,
    cameraHeight: 1.2,
  );

  // 2. Services
  final geoService = GeoService();
  final tfliteService = TFLiteService();
  await tfliteService.loadModel();

  final ttsService = TtsService();
  final hapticService = HapticService();
  final outputCoordinator = OutputCoordinator(ttsService, hapticService);

  final cameraService = CameraService();

  // 3. Repositories
  final mlRepository = MLRepositoryImpl(tfliteService);
  final laneEngine = LaneEngine(calibration);
  final laneRepository = LaneRepositoryImpl(db);
  final roadRepository = RoadRepositoryImpl(db);
  final geoRepository = GeoRepositoryImpl(db);
  final drivingRepository = DrivingRepositoryImpl(db);

  // Engines
  final obstacleEngine = ObstacleEngine();
  final trafficEngine = OncomingTrafficEngine(calibration);
  final steeringEngine = SteeringIntentEngine(trafficEngine);
  final temporalSteering = TemporalSteeringEngine(steeringEngine);
  final kalmanLaneTracker = KalmanLaneTracker();
  final virtualLaneGenerator = VirtualLaneGenerator(kalmanLaneTracker);
  final brakingEngine = BrakingHorizonEngine(calibration);
  final roadBehaviourEngine = RoadBehaviourEngine();
  

  // 4. Frame processor (no MLRepository needed)
  final frameProcessor = FrameProcessor(
    laneEngine,
    laneRepository,
    roadRepository,
    geoRepository,
    drivingRepository,
    geoService,
    calibration,
    sessionId,
    obstacleEngine,
    trafficEngine,
    temporalSteering,
    kalmanLaneTracker,
    virtualLaneGenerator,
    brakingEngine,
    roadBehaviourEngine,
  );
  frameProcessor.startGeoUpdates();

  // 5. ViewModel – now takes MLRepository
  final viewModel = CameraViewModel(
    cameraService,
    frameProcessor,
    mlRepository, // <-- pass MLRepository
    outputCoordinator,
  );

  await viewModel.initialize();
  return viewModel;
}

Future<void> _requestPermissions() async {
  await [Permission.camera, Permission.location].request();
  if (!await Permission.camera.isGranted) {
    throw Exception('Camera permission denied');
  }
}

class _AppLifecycleObserver extends WidgetsBindingObserver {
  final AppDatabase db;
  _AppLifecycleObserver(this.db);
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) db.close();
  }
}
