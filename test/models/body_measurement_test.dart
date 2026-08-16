import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/body_measurement.dart';

void main() {
  group('BodyMeasurement Model Tests', () {
    test('Should calculate BMI and BMI category correctly', () {
      final measurement = BodyMeasurement(
        id: 'm1',
        date: DateTime(2026, 8, 16),
        weight: 75.0,
        height: 180.0,
        bodyFatPercentage: 15.0,
        musclePercentage: 42.0,
        waterPercentage: 58.0,
      );

      // BMI = 75 / (1.80 * 1.80) = 23.148...
      expect(measurement.bmi, isNotNull);
      expect(measurement.bmi!, closeTo(23.15, 0.01));
      expect(measurement.bmiCategory, equals('Corpulence normale'));
    });

    test('Should calculate fat, muscle, and water mass in kg', () {
      final measurement = BodyMeasurement(
        id: 'm1',
        date: DateTime(2026, 8, 16),
        weight: 80.0,
        bodyFatPercentage: 15.0,
        musclePercentage: 40.0,
        waterPercentage: 60.0,
      );

      expect(measurement.fatMassKg, equals(12.0));
      expect(measurement.muscleMassKg, equals(32.0));
      expect(measurement.waterMassKg, equals(48.0));
    });

    test('Should serialize to JSON and deserialize from JSON correctly', () {
      final original = BodyMeasurement(
        id: 'm_test_123',
        date: DateTime(2026, 8, 16, 10, 0),
        weight: 78.5,
        height: 182.0,
        bodyFatPercentage: 14.2,
        musclePercentage: 43.1,
        waterPercentage: 59.3,
        boneMass: 3.4,
        note: 'À jeun le matin',
      );

      final json = original.toJson();
      final restored = BodyMeasurement.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.date.year, equals(original.date.year));
      expect(restored.date.month, equals(original.date.month));
      expect(restored.date.day, equals(original.date.day));
      expect(restored.weight, equals(original.weight));
      expect(restored.height, equals(original.height));
      expect(restored.bodyFatPercentage, equals(original.bodyFatPercentage));
      expect(restored.musclePercentage, equals(original.musclePercentage));
      expect(restored.waterPercentage, equals(original.waterPercentage));
      expect(restored.boneMass, equals(original.boneMass));
      expect(restored.note, equals(original.note));
    });

    test('Should support copyWith', () {
      final original = BodyMeasurement(
        id: 'm1',
        date: DateTime(2026, 8, 16),
        weight: 70.0,
      );

      final updated = original.copyWith(weight: 71.5, note: 'Updated note');
      expect(updated.id, equals('m1'));
      expect(updated.weight, equals(71.5));
      expect(updated.note, equals('Updated note'));
    });
  });
}
