import 'dart:convert';
import '../../domain/repositories/driving_repository.dart';
import '../../database/app_database.dart';
import 'package:drift/drift.dart';

class DrivingRepositoryImpl implements DrivingRepository {
  final AppDatabase _db;

  DrivingRepositoryImpl(this._db);

  @override
  Future<void> logEvent({
    required String sessionId,
    required String eventType,
    required double severity,
    required double confidence,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  }) async {
    final now = DateTime.now();

    await _db.into(_db.drivingEvents).insert(
      DrivingEventsCompanion.insert(
        timestamp: now,
        sessionId: Value(sessionId),
        eventType: eventType,
        severity: severity,
        confidence: confidence,
        latitude: Value(latitude),
        longitude: Value(longitude),
        metadata: Value(metadata != null ? jsonEncode(metadata) : null),
      ),
    );
  }
}