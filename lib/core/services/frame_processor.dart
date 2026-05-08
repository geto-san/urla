import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:urla/core/engine/lane_engine.dart';
import 'package:urla/core/engine/obstacle_engine.dart';
import 'package:urla/core/engine/oncoming_traffic_engine.dart';
import 'package:urla/core/engine/steering_temporal_engine.dart';
import 'package:urla/data/runtime/models/detection_model.dart';
import 'package:urla/data/runtime/models/frame_processing_result.dart';
import 'package:urla/data/runtime/models/geo_data.dart';
import '../../data/runtime/models/lane_model.dart';
import '../../data/domain/models/geo_model.dart';
import '../../data/domain/models/road_model.dart';
import '../../data/domain/repositories/lane_repository.dart';
import '../../data/domain/repositories/road_repository.dart';
import '../../data/domain/repositories/geo_repository.dart';
import '../../data/domain/repositories/driving_repository.dart';
import '../services/geo_service.dart';
import '../engine/kalman_lane_tracker.dart';
import '../engine/virtual_lane_generator.dart';
import '../engine/braking_horizon_engine.dart';
import '../engine/road_behavior_engine.dart';
import '../utils/camera_calibration.dart';

/// Holds detection results and original frame dimensions
class _DetectionFrame {
  final List<DetectionModel> detections;
  final int width;
  final int height;
  const _DetectionFrame({
    required this.detections,
    required this.width,
    required this.height,
  });
}

/// Central orchestrator of the perception pipeline.
/// Receives detections (from ML run externally) and produces lane, geo, events, and results.
class FrameProcessor {
  final LaneEngine _laneEngine;
  final LaneRepository _laneRepository;
  final RoadRepository _roadRepository;
  final GeoRepository _geoRepository;
  final DrivingRepository _drivingRepository;
  final GeoService _geoService;
  final DynamicCalibration _calibration;
  final String _sessionId;
  final ObstacleEngine _obstacleEngine;
  final OncomingTrafficEngine _trafficEngine;
  final TemporalSteeringEngine _temporalSteering;
  final KalmanLaneTracker _kalmanTracker;
  final VirtualLaneGenerator _virtualLaneGenerator;
  final BrakingHorizonEngine _brakingEngine;
  final RoadBehaviourEngine _roadBehaviourEngine;

  // Use a simple queue for pending detection frames
  final int _maxQueueSize = 2;
  final _queue = <_DetectionFrame>[];
  bool _isProcessing = false;

  // Fields for geo data
  GeoData? _cachedGeo;
  Timer? _geoTimer;

  // Cached road model — refreshed every 10 s to avoid blocking the frame loop.
  RoadModel? _cachedRoadModel;
  Timer? _roadModelTimer;

  final StreamController<LaneModel> _laneStream = StreamController.broadcast();
  final StreamController<FrameProcessingResult> _resultStream =
      StreamController.broadcast();
  final StreamController<GeoData> _geoStreamController =
      StreamController<GeoData>.broadcast();

  Stream<LaneModel> get laneStream => _laneStream.stream;
  Stream<FrameProcessingResult> get resultStream => _resultStream.stream;
  Stream<GeoData> get geoStream => _geoStreamController.stream;

  FrameProcessor(
    this._laneEngine,
    this._laneRepository,
    this._roadRepository,
    this._geoRepository,
    this._drivingRepository,
    this._geoService,
    this._calibration,
    this._sessionId,
    this._obstacleEngine,
    this._trafficEngine,
    this._temporalSteering,
    this._kalmanTracker,
    this._virtualLaneGenerator,
    this._brakingEngine,
    this._roadBehaviourEngine,
    // MLRepository is no longer needed here
  );

  /// Called from the ViewModel after ML inference is done.
  void submitDetections(
    List<DetectionModel> detections,
    int width,
    int height,
  ) {
    if (_queue.length >= _maxQueueSize) _queue.removeAt(0);

    _queue.add(
      _DetectionFrame(detections: detections, width: width, height: height),
    );
    _process();
  }

  /// Start polling the GPS at a fixed interval.
  /// Call this after construction (e.g., from main.dart or the ViewModel).
  void startGeoUpdates() {
    _geoTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        _cachedGeo = await _geoService.getCurrentLocation();
        _geoStreamController.add(_cachedGeo!);
      } catch (_) {
        // keep the last known value
      }
    });

    // Refresh the road model from DB every 10 s — cheap enough to not block.
    _roadModelTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final geo = _cachedGeo;
      if (geo == null) return;
      try {
        final id = '${geo.latitude.toStringAsFixed(4)}_${geo.longitude.toStringAsFixed(4)}';
        _cachedRoadModel = await _roadRepository.getRoadStats(id);
      } catch (e) {
        debugPrint('Road model refresh failed: $e');
      }
    });
  }

  Future<void> _process() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      while (_queue.isNotEmpty) {
        final frame = _queue.removeAt(0);
        try {
          await _processDetections(frame);
        } catch (e, stackTrace) {
          debugPrint('FrameProcessor error: $e\n$stackTrace');
          // Optionally emit an error result
          // _resultStream.add(FrameProcessingResult.error(e.toString()));
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processDetections(_DetectionFrame frame) async {
    final detections = frame.detections;
    final frameW = frame.width;
    final frameH = frame.height;
    if (detections.isEmpty) return;

    // 1. Raw lane geometry from engine
    LaneModel rawLane = _laneEngine.buildLane(detections);

    // 2. Kalman smoothing
    LaneModel smoothLane = _kalmanTracker.update(rawLane);

    // 3. Virtual lane fallback if confidence low or empty
    const trigger = VirtualLaneGenerator.triggerThreshold;
    if (smoothLane.confidence < trigger || smoothLane.centerLine.isEmpty) {
      // Attempt virtual generation
      final historicalWidth = smoothLane.laneWidth; // or fetch from DB?
      final virtual = _virtualLaneGenerator.generate(
        raw: smoothLane,
        detections: detections,
        historicalWidthM: historicalWidth,
        geo: _cachedGeo,
      );
      if (virtual != null) {
        smoothLane = virtual;
      } else {
        // no lane at all – still emit result with detections only
        debugPrint('No lane available (real or virtual)');
        final result = FrameProcessingResult(
          detections: detections,
          frameWidth:  frameW,
          frameHeight: frameH,
        );
        _resultStream.add(result);
        return;
      }
    }

    // 4. Save smoothed lane (fire‑and‑forget)
    _fireAndForget(
      () => _laneRepository.saveLane(smoothLane, sessionId: _sessionId),
      'saveLane',
    );

    if (_cachedGeo == null) {
      final result = FrameProcessingResult(
        lane:        smoothLane,
        detections:  detections,
        frameWidth:  frameW,
        frameHeight: frameH,
      );
      _resultStream.add(result);
      return;
    }
    final geo = _cachedGeo!;

    // 5. Obstacle & traffic
    final obstacle = _obstacleEngine.evaluate(detections, smoothLane);
    final traffic = _trafficEngine.evaluate(detections, smoothLane);

    // 6. Overtake (temporal)
    final overtake = _temporalSteering.evaluate(
      smoothLane,
      detections,
      obstacle.obstacleAhead,
      traffic.vehicleDetectedAhead,
    );

    // 7. Braking
    final braking = _brakingEngine.evaluate(
      obstacle: obstacle,
      geo: geo,
      lane: smoothLane,
    );

    // 8. Road behaviour — uses cached road model (refreshed every 10 s).
    //    Applies historical bias to the overtake decision when enough data exists.
    final roadBias = _roadBehaviourEngine.evaluate(_cachedRoadModel);
    final effectiveOvertake = roadBias.hasOverride ? roadBias.overtakeOverride! : overtake;

    // 9. Geo grid, road segment, event logging (fire‑and‑forget) – use smoothLane
    final gridCoords = _geoRepository.toGridCoords(geo.latitude, geo.longitude);
    final updatedCell = GeoCellModel(
      x: gridCoords.x,
      y: gridCoords.y,
      riskScore: smoothLane.driftScore,
      stability: smoothLane.confidence,
      sampleCount: 1,
    );
    _fireAndForget(() => _geoRepository.updateCell(updatedCell), 'updateCell');
    _fireAndForget(
      () => _roadRepository.updateRoadFromLane(
        geo.latitude,
        geo.longitude,
        smoothLane,
      ),
      'updateRoadFromLane',
    );
    _fireAndForget(
      () => _drivingRepository.logEvent(
        sessionId: _sessionId,
        eventType: 'lane_tracking',
        severity: smoothLane.driftScore,
        confidence: smoothLane.confidence,
        latitude: geo.latitude,
        longitude: geo.longitude,
      ),
      'logEvent',
    );

    // 10. Build full result
    final result = FrameProcessingResult(
      lane:            smoothLane,
      detections:      detections,
      obstacle:        obstacle,
      traffic:         traffic,
      overtakeDecision: effectiveOvertake,
      brakingState:    braking,
      frameWidth:      frameW,
      frameHeight:     frameH,
    );
    _resultStream.add(result);
  }

  void _fireAndForget(Future<void> Function() action, String description) {
    unawaited(
      Future.sync(action).catchError((e, st) {
        debugPrint('Async task "$description" failed: $e\n$st');
      }),
    );
  }

  Future<void> dispose() async{
    _geoTimer?.cancel();
    _roadModelTimer?.cancel();
    _laneStream.close();
    _resultStream.close();
    _queue.clear();
    await _geoStreamController.close();
  }
}
