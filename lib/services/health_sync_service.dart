import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

abstract class HealthSyncService {
  Future<bool> requestPermissions();
  Future<bool> writeWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required String activityName,
    double? calories,
  });
  Future<Map<String, double?>> fetchMetrics({
    required DateTime startTime,
    required DateTime endTime,
  });
}

class FlutterHealthSyncService implements HealthSyncService {
  final Health _health = Health();

  final List<HealthDataType> _dataTypes = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.HEART_RATE,
  ];

  final List<HealthDataAccess> _permissions = [
    HealthDataAccess.READ_WRITE, // For Calories
    HealthDataAccess.READ,       // For Heart Rate
  ];

  @override
  Future<bool> requestPermissions() async {
    try {
      // Configuration pour Health Connect sur Android si nécessaire
      // Configure permissions
      final bool? hasPermissions = await _health.hasPermissions(_dataTypes, permissions: _permissions);
      if (hasPermissions == true) {
        return true;
      }
      final bool authorized = await _health.requestAuthorization(_dataTypes, permissions: _permissions);
      return authorized;
    } catch (e) {
      debugPrint("Erreur de demande d'autorisation Health: $e");
      return false;
    }
  }

  @override
  Future<bool> writeWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required String activityName,
    double? calories,
  }) async {
    try {
      final bool permGranted = await requestPermissions();
      if (!permGranted) return false;

      // Écrit le workout (séance de musculation)
      final bool success = await _health.writeWorkoutData(
        activityType: HealthWorkoutActivityType.STRENGTH_TRAINING,
        start: startTime,
        end: endTime,
        totalEnergyBurned: calories?.toInt(),
      );

      return success;
    } catch (e) {
      debugPrint("Erreur lors de l'enregistrement de l'entraînement dans le Health Store: $e");
      return false;
    }
  }

  @override
  Future<Map<String, double?>> fetchMetrics({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final Map<String, double?> metrics = {
      'averageHeartRate': null,
      'activeCaloriesBurned': null,
    };

    try {
      final bool permGranted = await requestPermissions();
      if (!permGranted) return metrics;

      final List<HealthDataPoint> dataPoints = await _health.getHealthDataFromTypes(
        types: _dataTypes,
        startTime: startTime,
        endTime: endTime,
      );

      double heartRateSum = 0;
      int heartRateCount = 0;
      double caloriesSum = 0;

      for (var point in dataPoints) {
        if (point.type == HealthDataType.HEART_RATE) {
          final val = double.tryParse(point.value.toString());
          if (val != null) {
            heartRateSum += val;
            heartRateCount++;
          }
        } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
          final val = double.tryParse(point.value.toString());
          if (val != null) {
            caloriesSum += val;
          }
        }
      }

      if (heartRateCount > 0) {
        metrics['averageHeartRate'] = heartRateSum / heartRateCount;
      }
      if (caloriesSum > 0) {
        metrics['activeCaloriesBurned'] = caloriesSum;
      }
    } catch (e) {
      debugPrint("Erreur lors de la récupération des données de santé : $e");
    }

    return metrics;
  }
}

class MockHealthSyncService implements HealthSyncService {
  @override
  Future<bool> requestPermissions() async {
    return true;
  }

  @override
  Future<bool> writeWorkout({
    required DateTime startTime,
    required DateTime endTime,
    required String activityName,
    double? calories,
  }) async {
    return true;
  }

  @override
  Future<Map<String, double?>> fetchMetrics({
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    // Renvoie des données réalistes simulées pour tester
    final durationMinutes = endTime.difference(startTime).inMinutes;
    final simulatedCalories = durationMinutes * 6.5; // ex: 6.5 kcal/min
    final simulatedHeartRate = 120.0 + (durationMinutes % 20); // 120 - 140 bpm

    return {
      'averageHeartRate': simulatedHeartRate,
      'activeCaloriesBurned': simulatedCalories,
    };
  }
}
