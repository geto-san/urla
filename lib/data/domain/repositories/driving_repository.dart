abstract class DrivingRepository {
  
  Future<void> logEvent({
    required String sessionId,
    required String eventType,
    required double severity,
    required double confidence,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? metadata,
  });
}