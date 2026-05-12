import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/runtime/models/detection_model.dart';
import '../../data/runtime/models/frame_processing_result.dart';
import '../../data/runtime/models/geo_data.dart';
import '../../data/domain/models/geo_model.dart';
import '../../data/domain/models/road_model.dart';
import '../../data/domain/repositories/lane_repository.dart';
import '../../data/domain/repositories/road_repository.dart';
import '../../data/domain/repositories/geo_repository.dart';
import '../../data/domain/repositories/driving_repository.dart';
import '../engine/kalman_lane_tracker.dart';
import '../engine/lane_engine.dart';
import '../engine/obstacle_engine.dart';
import '../engine/oncoming_traffic_engine.dart';
import '../engine/steering_temporal_engine.dart';
import '../engine/virtual_lane_generator.dart';
import '../engine/braking_horizon_engine.dart';
import '../engine/road_behavior_engine.dart';
import '../services/geo_service.dart';
import '../utils/camera_calibration.dart';
import '../../data/runtime/models/lane_model.dart';

/// Holds a pending detection batch alongside its frame dimensions.
class _Frame {
  final List<DetectionModel> detections;
  final int width;
  final int height;
  const _Frame(this.detections, this.width, this.height);
}

/// Central perception orchestrator.
///
/// Changes vs original:
///   • Single-slot queue: newest frame always wins; no silent mid-drop.
///   • Priority split: safety path (lane + obstacle + braking) runs first,
///     analytics (geo, DB, road behaviour) run async after result is emitted.
///   • Debounced DB writes: batched every [_dbFlushInterval] to prevent IO
///     spikes inside the real-time loop.
///   • [startGeoUpdates] remains unchanged — GPS polling is already correct.
class FrameProcessor {
  static const _dbFlushInterval = Duration(milliseconds: 500);

  final LaneEngine               _laneEngine;
  final LaneRepository           _laneRepo;
  final RoadRepository           _roadRepo;
  final GeoRepository            _geoRepo;
  final DrivingRepository        _drivingRepo;
  final GeoService               _geoService;
  final DynamicCalibration       _calibration;
  final String                   _sessionId;
  final ObstacleEngine           _obstacleEngine;
  final OncomingTrafficEngine    _trafficEngine;
  final TemporalSteeringEngine   _temporalSteering;
  final KalmanLaneTracker        _kalmanTracker;
  final VirtualLaneGenerator     _virtualLaneGenerator;
  final BrakingHorizonEngine     _brakingEngine;
  final RoadBehaviourEngine      _roadBehaviourEngine;

  // ── Single-slot buffer ──────────────────────────────────────
  _Frame? _pending;
  bool    _processing = false;

  // ── Geo + road model cache ───────────────────────────────────
  GeoData?   _cachedGeo;
  RoadModel? _cachedRoad;
  Timer?     _geoTimer;
  Timer?     _roadTimer;

  // ── DB write debounce ────────────────────────────────────────
  Timer?     _dbFlushTimer;
  _DbBatch   _batch = _DbBatch();

  // ── Output streams ───────────────────────────────────────────
  final _resultCtrl = StreamController<FrameProcessingResult>.broadcast();
  final _geoCtrl    = StreamController<GeoData>.broadcast();
  final _laneCtrl   = StreamController<LaneModel>.broadcast();

  Stream<FrameProcessingResult> get resultStream => _resultCtrl.stream;
  Stream<GeoData>               get geoStream    => _geoCtrl.stream;
  Stream<LaneModel>             get laneStream   => _laneCtrl.stream;

  FrameProcessor(
    this._laneEngine,
    this._laneRepo,
    this._roadRepo,
    this._geoRepo,
    this._drivingRepo,
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
  );

  // ─────────────────────────────────────────────────────────────
  // PUBLIC API
  // ─────────────────────────────────────────────────────────────

  /// Called by the ViewModel after ML inference completes.
  /// Only the most recent frame is processed; older ones are evicted.
  void submitDetections(List<DetectionModel> detections, int w, int h) {
    _pending = _Frame(detections, w, h); // evicts previous if any
    _drain();
  }

  /// Start GPS polling and periodic road-model refresh.
  void startGeoUpdates() {
    _geoTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        _cachedGeo = await _geoService.getCurrentLocation();
        _geoCtrl.add(_cachedGeo!);
      } catch (_) {}
    });

    _roadTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final geo = _cachedGeo;
      if (geo == null) return;
      try {
        final id =
            '${geo.latitude.toStringAsFixed(4)}_${geo.longitude.toStringAsFixed(4)}';
        _cachedRoad = await _roadRepo.getRoadStats(id);
      } catch (e) {
        debugPrint('Road model refresh failed: $e');
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // FRAME DRAIN
  // ─────────────────────────────────────────────────────────────

  void _drain() {
    if (_processing || _pending == null) return;
    _processing = true;

    final frame = _pending!;
    _pending = null;

    // Run asynchronously so we don't block the calling ViewModel.
    Future.microtask(() async {
      try {
        await _processFrame(frame);
      } catch (e, st) {
        debugPrint('FrameProcessor error: $e\n$st');
      } finally {
        _processing = false;
        // Process the next frame if one arrived while we were busy.
        if (_pending != null) _drain();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CORE PIPELINE
  // ─────────────────────────────────────────────────────────────

  Future<void> _processFrame(_Frame frame) async {
    if (frame.detections.isEmpty) return;

    // ── SAFETY PATH (synchronous, must complete before emitting) ─

    // 1. Lane geometry
    LaneModel rawLane = _laneEngine.buildLane(frame.detections);

    // 2. Kalman smoothing
    LaneModel lane = _kalmanTracker.update(rawLane);

    // 3. Virtual lane fallback
    if (lane.confidence < VirtualLaneGenerator.triggerThreshold ||
        lane.centerLine.isEmpty) {
      final virtual = _virtualLaneGenerator.generate(
        raw:               lane,
        detections:        frame.detections,
        historicalWidthM:  lane.laneWidth,
        geo:               _cachedGeo,
      );
      if (virtual != null) {
        lane = virtual;
      } else {
        // Emit detections-only result and bail
        _resultCtrl.add(FrameProcessingResult(
          detections:  frame.detections,
          frameWidth:  frame.width,
          frameHeight: frame.height,
        ));
        return;
      }
    }

    // 4. Obstacle + traffic
    final obstacle = _obstacleEngine.evaluate(frame.detections, lane);
    final traffic  = _trafficEngine.evaluate(frame.detections, lane);

    // 5. Overtake + braking
    final geo = _cachedGeo;
    final overtake = _temporalSteering.evaluate(
      lane,
      frame.detections,
      obstacle.obstacleAhead,
      traffic.vehicleDetectedAhead,
    );
    final braking = geo != null
        ? _brakingEngine.evaluate(obstacle: obstacle, geo: geo, lane: lane)
        : null;

    // 6. Road behaviour bias
    final roadBias       = _roadBehaviourEngine.evaluate(_cachedRoad);
    final effectiveOvertake =
        roadBias.hasOverride ? roadBias.overtakeOverride! : overtake;

    // ── EMIT RESULT ────────────────────────────────────────────
    // Emit immediately so the UI gets the safety-critical state
    // before any IO touches the event loop.
    _resultCtrl.add(FrameProcessingResult(
      lane:             lane,
      detections:       frame.detections,
      obstacle:         obstacle,
      traffic:          traffic,
      overtakeDecision: effectiveOvertake,
      brakingState:     braking,
      frameWidth:       frame.width,
      frameHeight:      frame.height,
    ));
    _laneCtrl.add(lane);

    // ── ANALYTICS PATH (debounced, runs after result is emitted) ─
    if (geo != null) {
      _scheduleBatch(lane, geo);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DEBOUNCED DB WRITES
  // ─────────────────────────────────────────────────────────────

  void _scheduleBatch(LaneModel lane, GeoData geo) {
    // Accumulate into current batch
    _batch.lane  = lane;
    _batch.geo   = geo;

    _dbFlushTimer ??= Timer(_dbFlushInterval, _flushBatch);
  }

  Future<void> _flushBatch() async {
    _dbFlushTimer = null;
    final batch = _batch;
    _batch = _DbBatch(); // reset for next window

    final lane = batch.lane;
    final geo  = batch.geo;
    if (lane == null || geo == null) return;

    _fireAndForget(() => _laneRepo.saveLane(lane, sessionId: _sessionId), 'saveLane');

    final coords    = _geoRepo.toGridCoords(geo.latitude, geo.longitude);
    final geoCell   = GeoCellModel(
      x:           coords.x,
      y:           coords.y,
      riskScore:   lane.driftScore,
      stability:   lane.confidence,
      sampleCount: 1,
    );
    _fireAndForget(() => _geoRepo.updateCell(geoCell), 'updateCell');
    _fireAndForget(
      () => _roadRepo.updateRoadFromLane(geo.latitude, geo.longitude, lane),
      'updateRoadFromLane',
    );
    _fireAndForget(
      () => _drivingRepo.logEvent(
        sessionId:  _sessionId,
        eventType:  'lane_tracking',
        severity:   lane.driftScore,
        confidence: lane.confidence,
        latitude:   geo.latitude,
        longitude:  geo.longitude,
      ),
      'logEvent',
    );
  }

  void _fireAndForget(Future<void> Function() fn, String label) {
    unawaited(
      Future.sync(fn).catchError((e, st) {
        debugPrint('Async "$label" failed: $e\n$st');
      }),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    _geoTimer?.cancel();
    _roadTimer?.cancel();
    _dbFlushTimer?.cancel();
    await _flushBatch(); // flush any unsent writes
    await Future.wait([
      _resultCtrl.close(),
      _geoCtrl.close(),
      _laneCtrl.close(),
    ]);
  }
}

// Simple mutable batch accumulator
class _DbBatch {
  LaneModel? lane;
  GeoData?   geo;
}