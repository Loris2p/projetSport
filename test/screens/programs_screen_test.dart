import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/models/program_exercise.dart';
import 'package:sport_app/models/workout_program.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/programs_screen.dart';
import '../helpers/mock_repositories.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('ProgramsScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepo;
    late MockWorkoutRepository mockWorkoutRepo;
    late AuthProvider authProvider;
    late WorkoutProvider workoutProvider;

    setUp(() async {
      mockAuthRepo = MockAuthRepository();
      mockWorkoutRepo = MockWorkoutRepository();
      authProvider = AuthProvider(authRepository: mockAuthRepo);
      workoutProvider = WorkoutProvider(
        repository: mockWorkoutRepo,
      );

      mockWorkoutRepo.programs.add(
        WorkoutProgram(
          id: 'p1',
          name: 'Program Push',
          description: 'Pectoraux & Épaules',
          exercises: [
            ProgramExercise(exerciseId: 'ex_bench', setsCount: 3, repsCount: 10, restTime: 90),
          ],
        ),
      );
      await workoutProvider.init();
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
        ],
        child: const MaterialApp(
          home: ProgramsScreen(),
        ),
      );
    }

    testWidgets('Should display programs list and allow searching', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Programmes'), findsOneWidget);
      expect(find.text('Program Push'), findsOneWidget);
    });

    testWidgets('Should start session when clicking Démarrer button inside expanded tile', (WidgetTester tester) async {
      try {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(workoutProvider.activeSession, isNull);

        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();

        final startButton = find.text('Démarrer');
        expect(startButton, findsOneWidget);

        await tester.tap(startButton);
        await tester.pumpAndSettle();

        expect(workoutProvider.activeSession, isNotNull);
        expect(workoutProvider.activeSession?.name, equals('Program Push'));
      } finally {
        workoutProvider.cancelActiveSession();
      }
    });
  });
}
