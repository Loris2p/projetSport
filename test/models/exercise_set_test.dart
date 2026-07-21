import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise_set.dart';

void main() {
  group('ExerciseSet Model Tests', () {
    test('Should calculate estimated 1RM accurately using Epley formula', () {
      // Reps <= 1 should return weight
      final set1Rep = ExerciseSet(id: 'set_1', weight: 100.0, reps: 1);
      expect(set1Rep.estimated1RM, equals(100.0));

      final set0Rep = ExerciseSet(id: 'set_0', weight: 100.0, reps: 0);
      expect(set0Rep.estimated1RM, equals(100.0));

      // 100kg x 10 reps -> 100 * (1 + 10/30) = 133.333...
      final set10Reps = ExerciseSet(id: 'set_10', weight: 100.0, reps: 10);
      expect(set10Reps.estimated1RM, closeTo(133.33, 0.01));

      // 80kg x 6 reps -> 80 * (1 + 6/30) = 80 * 1.2 = 96.0
      final set6Reps = ExerciseSet(id: 'set_6', weight: 80.0, reps: 6);
      expect(set6Reps.estimated1RM, equals(96.0));
    });

    test('Should initialize with expected default values', () {
      final set = ExerciseSet(id: 'set_default');
      expect(set.id, equals('set_default'));
      expect(set.weight, equals(0.0));
      expect(set.reps, equals(0));
      expect(set.isCompleted, isFalse);
      expect(set.type, equals(SetType.normal));
      expect(set.isWeightPR, isFalse);
      expect(set.is1RMPR, isFalse);
      expect(set.duration, equals(0));
      expect(set.distance, equals(0.0));
    });

    test('Should serialize to JSON and restore via fromJson (Roundtrip)', () {
      final original = ExerciseSet(
        id: 'set_full',
        weight: 95.5,
        reps: 8,
        isCompleted: true,
        type: SetType.dropSet,
        isWeightPR: true,
        is1RMPR: false,
        duration: 120,
        distance: 2.5,
      );

      final json = original.toJson();
      expect(json['id'], equals('set_full'));
      expect(json['weight'], equals(95.5));
      expect(json['reps'], equals(8));
      expect(json['isCompleted'], isTrue);
      expect(json['type'], equals('dropSet'));
      expect(json['isWeightPR'], isTrue);
      expect(json['is1RMPR'], isFalse);
      expect(json['duration'], equals(120));
      expect(json['distance'], equals(2.5));

      final restored = ExerciseSet.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.weight, equals(original.weight));
      expect(restored.reps, equals(original.reps));
      expect(restored.isCompleted, equals(original.isCompleted));
      expect(restored.type, equals(original.type));
      expect(restored.isWeightPR, equals(original.isWeightPR));
      expect(restored.is1RMPR, equals(original.is1RMPR));
      expect(restored.duration, equals(original.duration));
      expect(restored.distance, equals(original.distance));
    });

    test('Should fallback to SetType.normal when fromJson receives unknown set type', () {
      final json = {
        'id': 'set_unknown',
        'weight': 50,
        'reps': 12,
        'type': 'superSetTypeUnknown',
      };

      final restored = ExerciseSet.fromJson(json);
      expect(restored.type, equals(SetType.normal));
    });
  });
}
