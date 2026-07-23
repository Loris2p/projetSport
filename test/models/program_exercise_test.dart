import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise_type.dart';
import 'package:sport_app/models/program_exercise.dart';

void main() {
  group('ProgramExercise Model Tests', () {
    test('Should create ProgramExercise with specified parameters', () {
      final pe = ProgramExercise(
        exerciseId: 'ex_bench',
        type: ExerciseType.reps,
        setsCount: 4,
        repsCount: 10,
        restTime: 90,
      );

      expect(pe.exerciseId, equals('ex_bench'));
      expect(pe.type, equals(ExerciseType.reps));
      expect(pe.setsCount, equals(4));
      expect(pe.repsCount, equals(10));
      expect(pe.restTime, equals(90));
      expect(pe.durationTarget, equals(0));
      expect(pe.distanceTarget, equals(0.0));
    });

    test('Should serialize to JSON and restore via fromJson (Roundtrip)', () {
      final original = ProgramExercise(
        exerciseId: 'ex_run',
        type: ExerciseType.cardio,

        setsCount: 1,
        repsCount: 1,
        restTime: 180,
        durationTarget: 1800,
        distanceTarget: 5.0,
      );

      final json = original.toJson();
      expect(json['exerciseId'], equals('ex_run'));
      expect(json['type'], equals('cardio'));

      expect(json['setsCount'], equals(1));
      expect(json['repsCount'], equals(1));
      expect(json['restTime'], equals(180));
      expect(json['durationTarget'], equals(1800));
      expect(json['distanceTarget'], equals(5.0));

      final restored = ProgramExercise.fromJson(json);
      expect(restored.exerciseId, equals(original.exerciseId));
      expect(restored.type, equals(original.type));
      expect(restored.setsCount, equals(original.setsCount));
      expect(restored.repsCount, equals(original.repsCount));
      expect(restored.restTime, equals(original.restTime));
      expect(restored.durationTarget, equals(original.durationTarget));
      expect(restored.distanceTarget, equals(original.distanceTarget));
    });
  });
}
