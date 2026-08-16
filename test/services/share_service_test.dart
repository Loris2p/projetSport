import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/exercise.dart';
import 'package:sport_app/models/workout_program.dart';
import 'package:sport_app/models/program_exercise.dart';
import 'package:sport_app/services/share_service.dart';

void main() {
  group('ShareService Tests', () {
    test('encodeProgram and decode program with custom exercises', () {
      final customEx = Exercise(
        id: 'custom_123',
        name: 'Développé Décliné Haltères',
        categories: ['Pectoraux'],
        isCustom: true,
      );

      final standardEx = Exercise(
        id: 'bench_press',
        name: 'Développé Couché',
        categories: ['Pectoraux'],
        isCustom: false,
      );

      final program = WorkoutProgram(
        id: 'prog_1',
        name: 'Pectoraux Massifs',
        description: 'Séance axée sur le haut des pecs',
        exercises: [
          ProgramExercise(
            exerciseId: 'custom_123',
            setsCount: 4,
            repsCount: 10,
            restTime: 90,
          ),
          ProgramExercise(
            exerciseId: 'bench_press',
            setsCount: 3,
            repsCount: 8,
            restTime: 120,
          ),
        ],
      );

      // 1. Encodage
      final code = ShareService.encodeProgram(program, [customEx, standardEx]);
      expect(code.startsWith('SPRT1_'), isTrue);

      // 2. Décodage
      final result = ShareService.decode(code);
      expect(result.isSuccess, isTrue);
      expect(result.type, equals(ShareDataType.program));
      expect(result.program?.name, equals('Pectoraux Massifs'));
      expect(result.program?.exercises.length, equals(2));
      expect(result.exercises.length, equals(1));
      expect(result.exercises.first.name, equals('Développé Décliné Haltères'));
    });

    test('encodeExercise and decode single exercise', () {
      final ex = Exercise(
        id: 'curl_incline',
        name: 'Curl Incliné',
        categories: ['Biceps', 'Bras'],
        notes: 'Bien étirer en bas du mouvement',
        isCustom: true,
      );

      final code = ShareService.encodeExercise(ex);
      expect(code.startsWith('SPRT1_'), isTrue);

      final result = ShareService.decode(code);
      expect(result.isSuccess, isTrue);
      expect(result.type, equals(ShareDataType.singleExercise));
      expect(result.exercises.length, equals(1));
      expect(result.exercises.first.name, equals('Curl Incliné'));
      expect(result.exercises.first.notes, equals('Bien étirer en bas du mouvement'));
    });

    test('decode invalid code returns failure result gracefully', () {
      final result = ShareService.decode('invalid_garbage_code_123');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });

    test('decode empty string returns failure result', () {
      final result = ShareService.decode('');
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, isNotNull);
    });
  });
}
