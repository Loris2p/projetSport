import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise_set.dart';
import 'package:sport_app/models/exercise_type.dart';
import 'package:sport_app/models/performed_exercise.dart';

void main() {
  group('PerformedExercise Model Tests', () {
    test('Should create PerformedExercise with sets and default values', () {
      final perfEx = PerformedExercise(
        exerciseId: 'ex_1',
        sets: [
          ExerciseSet(id: 's1', weight: 80, reps: 10, isCompleted: true),
        ],
      );

      expect(perfEx.exerciseId, equals('ex_1'));
      expect(perfEx.type, equals(ExerciseType.reps));
      expect(perfEx.sets.length, equals(1));
      expect(perfEx.notes, isNull);
      expect(perfEx.groupId, isNull);
    });

    test('Should serialize to JSON and restore via fromJson (Roundtrip)', () {
      final original = PerformedExercise(
        exerciseId: 'ex_superset',
        type: ExerciseType.isometry,

        sets: [
          ExerciseSet(id: 's1', duration: 60, isCompleted: true),
          ExerciseSet(id: 's2', duration: 45, isCompleted: false),
        ],
        notes: 'Garder le dos droit',
        groupId: 'group_A',
      );

      final json = original.toJson();
      expect(json['exerciseId'], equals('ex_superset'));
      expect(json['type'], equals('isometry'));

      expect(json['notes'], equals('Garder le dos droit'));
      expect(json['groupId'], equals('group_A'));
      expect((json['sets'] as List).length, equals(2));

      final restored = PerformedExercise.fromJson(json);
      expect(restored.exerciseId, equals(original.exerciseId));
      expect(restored.type, equals(original.type));
      expect(restored.notes, equals(original.notes));
      expect(restored.groupId, equals(original.groupId));
      expect(restored.sets.length, equals(2));
      expect(restored.sets.first.duration, equals(60));
    });
  });
}
