import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise_type.dart';

void main() {
  group('ExerciseType Model Tests', () {
    test('Should parse ExerciseType correctly from string values', () {
      expect(ExerciseType.fromString('reps'), equals(ExerciseType.reps));
      expect(ExerciseType.fromString('time'), equals(ExerciseType.time));
      expect(ExerciseType.fromString('distance'), equals(ExerciseType.distance));
    });

    test('Should fallback to ExerciseType.reps when string is null or invalid', () {
      expect(ExerciseType.fromString(null), equals(ExerciseType.reps));
      expect(ExerciseType.fromString(''), equals(ExerciseType.reps));
      expect(ExerciseType.fromString('invalid_type'), equals(ExerciseType.reps));
    });

    test('Should provide correct labels and headers for each type', () {
      expect(ExerciseType.reps.label, contains('Répétitions'));
      expect(ExerciseType.reps.headers, contains('POIDS (KG)'));

      expect(ExerciseType.time.label, contains('Temps'));
      expect(ExerciseType.time.headers, contains('TEMPS'));

      expect(ExerciseType.distance.label, contains('Distance'));
      expect(ExerciseType.distance.headers, contains('DISTANCE (KM)'));
    });
  });
}
