import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise_type.dart';

void main() {
  group('ExerciseType Model Tests', () {
    test('Should parse ExerciseType correctly from string values', () {
      expect(ExerciseType.fromString('reps'), equals(ExerciseType.reps));
      expect(ExerciseType.fromString('isometry'), equals(ExerciseType.isometry));
      expect(ExerciseType.fromString('cardio'), equals(ExerciseType.cardio));
      expect(ExerciseType.fromString('intervals'), equals(ExerciseType.intervals));
      expect(ExerciseType.fromString('amrap'), equals(ExerciseType.amrap));
      expect(ExerciseType.fromString('emom'), equals(ExerciseType.emom));
      expect(ExerciseType.fromString('forTime'), equals(ExerciseType.forTime));
      expect(ExerciseType.fromString('video'), equals(ExerciseType.video));
      expect(ExerciseType.fromString('tempo'), equals(ExerciseType.tempo));
      expect(ExerciseType.fromString('circuit'), equals(ExerciseType.circuit));

      // Test fallback for legacy terms
      expect(ExerciseType.fromString('time'), equals(ExerciseType.isometry));
      expect(ExerciseType.fromString('distance'), equals(ExerciseType.cardio));
    });

    test('Should fallback to ExerciseType.reps when string is null or invalid', () {
      expect(ExerciseType.fromString(null), equals(ExerciseType.reps));
      expect(ExerciseType.fromString(''), equals(ExerciseType.reps));
      expect(ExerciseType.fromString('invalid_type'), equals(ExerciseType.reps));
    });

    test('Should provide correct labels and headers for each type', () {
      expect(ExerciseType.reps.label, contains('Répétitions'));
      expect(ExerciseType.reps.headers, contains('POIDS (KG)'));

      expect(ExerciseType.isometry.label, contains('Isométrie'));
      expect(ExerciseType.isometry.headers, contains('DURÉE'));

      expect(ExerciseType.cardio.label, contains('Cardio'));
      expect(ExerciseType.cardio.headers, contains('DURÉE (MIN)'));
    });
  });
}

