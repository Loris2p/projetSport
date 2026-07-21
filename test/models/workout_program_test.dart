import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise_type.dart';
import 'package:sport_app/models/program_exercise.dart';
import 'package:sport_app/models/workout_program.dart';

void main() {
  group('WorkoutProgram Model Tests', () {
    test('Should create WorkoutProgram with exercises and optional superset groups', () {
      final program = WorkoutProgram(
        id: 'prog_push',
        name: 'Programme Push',
        description: 'Pectoraux, Épaules, Triceps',
        exercises: [
          ProgramExercise(exerciseId: 'ex_bench', type: ExerciseType.reps, setsCount: 4, repsCount: 10, restTime: 90),
          ProgramExercise(exerciseId: 'ex_dips', type: ExerciseType.reps, setsCount: 3, repsCount: 12, restTime: 60),
        ],
        exerciseGroups: {'ex_bench': 'group_1', 'ex_dips': 'group_1'},
      );

      expect(program.id, equals('prog_push'));
      expect(program.name, equals('Programme Push'));
      expect(program.description, equals('Pectoraux, Épaules, Triceps'));
      expect(program.exercises.length, equals(2));
      expect(program.exerciseGroups?['ex_bench'], equals('group_1'));
    });

    test('Should serialize to JSON and restore via fromJson (Roundtrip)', () {
      final original = WorkoutProgram(
        id: 'prog_pull',
        name: 'Programme Pull',
        description: 'Dos, Biceps',
        exercises: [
          ProgramExercise(exerciseId: 'ex_pullup', type: ExerciseType.reps, setsCount: 4, repsCount: 8, restTime: 90),
        ],
      );

      final json = original.toJson();
      expect(json['id'], equals('prog_pull'));
      expect(json['name'], equals('Programme Pull'));
      expect(json['description'], equals('Dos, Biceps'));
      expect((json['exercises'] as List).length, equals(1));

      final restored = WorkoutProgram.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.description, equals(original.description));
      expect(restored.exercises.length, equals(1));
      expect(restored.exercises.first.exerciseId, equals('ex_pullup'));
    });
  });
}
