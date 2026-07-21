import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/services/health_sync_service.dart';

void main() {
  group('MockHealthSyncService Tests', () {
    late MockHealthSyncService service;

    setUp(() {
      service = MockHealthSyncService();
    });

    test('Should return true for requestPermissions', () async {
      final result = await service.requestPermissions();
      expect(result, isTrue);
    });

    test('Should return true for writeWorkout', () async {
      final now = DateTime.now();
      final result = await service.writeWorkout(
        startTime: now.subtract(const Duration(minutes: 60)),
        endTime: now,
        activityName: 'Musculation',
        calories: 350.0,
      );
      expect(result, isTrue);
    });

    test('Should return realistic simulated health metrics based on session duration', () async {
      final startTime = DateTime.now().subtract(const Duration(minutes: 60));
      final endTime = DateTime.now();

      final metrics = await service.fetchMetrics(startTime: startTime, endTime: endTime);

      expect(metrics.containsKey('averageHeartRate'), isTrue);
      expect(metrics.containsKey('activeCaloriesBurned'), isTrue);
      expect(metrics['activeCaloriesBurned'], equals(60 * 6.5)); // 390 kcal
      expect(metrics['averageHeartRate'], greaterThanOrEqualTo(120.0));
      expect(metrics['averageHeartRate'], lessThanOrEqualTo(140.0));
    });
  });
}
