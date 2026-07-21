import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise_set.dart';
import 'package:sport_app/models/performed_exercise.dart';
import 'package:sport_app/models/workout_session.dart';

void main() {
  group('WorkoutSession Model Tests', () {
    test('Should create WorkoutSession with health metrics and performed exercises', () {
      final startTime = DateTime.now().subtract(const Duration(hours: 1));
      final endTime = DateTime.now();

      final session = WorkoutSession(
        id: 'sess_1',
        programId: 'prog_push',
        name: 'Séance Push Intensive',
        startTime: startTime,
        endTime: endTime,
        exercises: [
          PerformedExercise(
            exerciseId: 'ex_bench',
            sets: [ExerciseSet(id: 's1', weight: 80, reps: 10, isCompleted: true)],
          ),
        ],
        activeCaloriesBurned: 350.5,
        averageHeartRate: 135.0,
      );

      expect(session.id, equals('sess_1'));
      expect(session.programId, equals('prog_push'));
      expect(session.name, equals('Séance Push Intensive'));
      expect(session.startTime, equals(startTime));
      expect(session.endTime, equals(endTime));
      expect(session.exercises.length, equals(1));
      expect(session.activeCaloriesBurned, equals(350.5));
      expect(session.averageHeartRate, equals(135.0));
    });

    test('Should serialize to JSON and restore via fromJson (Roundtrip)', () {
      final startTime = DateTime.parse('2026-07-20T10:00:00.000Z');
      final endTime = DateTime.parse('2026-07-20T11:00:00.000Z');

      final original = WorkoutSession(
        id: 'sess_2',
        name: 'Séance Libre',
        startTime: startTime,
        endTime: endTime,
        exercises: [
          PerformedExercise(
            exerciseId: 'ex_squat',
            sets: [ExerciseSet(id: 's1', weight: 100, reps: 5, isCompleted: true)],
          ),
        ],
        activeCaloriesBurned: 400.0,
        averageHeartRate: 140.0,
      );

      final json = original.toJson();
      expect(json['id'], equals('sess_2'));
      expect(json['name'], equals('Séance Libre'));
      expect(json['startTime'], equals(startTime.toIso8601String()));
      expect(json['endTime'], equals(endTime.toIso8601String()));
      expect(json['activeCaloriesBurned'], equals(400.0));
      expect(json['averageHeartRate'], equals(140.0));

      final restored = WorkoutSession.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.startTime, equals(original.startTime));
      expect(restored.endTime, equals(original.endTime));
      expect(restored.exercises.length, equals(original.exercises.length));
      expect(restored.activeCaloriesBurned, equals(original.activeCaloriesBurned));
      expect(restored.averageHeartRate, equals(original.averageHeartRate));
    });
  });
}
