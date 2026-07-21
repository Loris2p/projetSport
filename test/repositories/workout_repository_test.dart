import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise.dart';
import 'package:sport_app/models/exercise_set.dart';
import 'package:sport_app/models/performed_exercise.dart';
import 'package:sport_app/models/program_exercise.dart';
import 'package:sport_app/models/workout_program.dart';
import 'package:sport_app/models/workout_session.dart';
import '../helpers/mock_repositories.dart';

void main() {
  group('WorkoutRepository Contract & Specifications Tests', () {
    late MockWorkoutRepository workoutRepo;

    setUp(() {
      workoutRepo = MockWorkoutRepository();
    });

    test('Should handle exercise CRUD operations', () async {
      final exercise = Exercise(id: 'ex_bench', name: 'Développé Couché', categories: ['Pectoraux']);

      await workoutRepo.saveExercise(exercise);
      expect(workoutRepo.getExercises().length, equals(1));
      expect(workoutRepo.getExercises().first.name, equals('Développé Couché'));

      final updatedExercise = Exercise(id: 'ex_bench', name: 'Bench Press Inc', categories: ['Pectoraux']);
      await workoutRepo.saveExercise(updatedExercise);
      expect(workoutRepo.getExercises().length, equals(1));
      expect(workoutRepo.getExercises().first.name, equals('Bench Press Inc'));

      await workoutRepo.deleteExercise('ex_bench');
      expect(workoutRepo.getExercises(), isEmpty);
    });

    test('Should handle program CRUD operations', () async {
      final program = WorkoutProgram(
        id: 'prog_push',
        name: 'Push Day',
        description: 'Pectoraux & Triceps',
        exercises: [ProgramExercise(exerciseId: 'ex_bench', setsCount: 3, repsCount: 10, restTime: 90)],
      );

      await workoutRepo.saveProgram(program);
      expect(workoutRepo.getPrograms().length, equals(1));

      await workoutRepo.deleteProgram('prog_push');
      expect(workoutRepo.getPrograms(), isEmpty);
    });

    test('Should handle session history CRUD operations', () async {
      final session = WorkoutSession(
        id: 'sess_1',
        name: 'Séance Push',
        startTime: DateTime.now(),
        exercises: [
          PerformedExercise(exerciseId: 'ex_bench', sets: [ExerciseSet(id: 's1', weight: 80, reps: 10, isCompleted: true)]),
        ],
      );

      await workoutRepo.saveSession(session);
      expect(workoutRepo.getHistory().length, equals(1));

      await workoutRepo.deleteSession('sess_1');
      expect(workoutRepo.getHistory(), isEmpty);
    });

    test('Should update currentUserId on setUserId', () async {
      await workoutRepo.setUserId('user_456');
      expect(workoutRepo.currentUserId, equals('user_456'));
    });
  });
}
