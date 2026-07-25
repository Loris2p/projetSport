import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sport_app/models/exercise_set.dart';
import 'package:sport_app/models/performed_exercise.dart';
import 'package:sport_app/models/workout_session.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/history_screen.dart';
import '../helpers/mock_repositories.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('fr_FR', null);
  });

  group('HistoryScreen Widget Tests', () {
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

      mockWorkoutRepo.history.add(
        WorkoutSession(
          id: 'sess_1',
          name: 'Séance Push Réalisée',
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          exercises: [
            PerformedExercise(
              exerciseId: 'ex_bench',
              sets: [ExerciseSet(id: 's1', weight: 80, reps: 10, isCompleted: true)],
            ),
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
          home: HistoryScreen(),
        ),
      );
    }

    testWidgets('Should display history sessions', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Historique'), findsOneWidget);

      final sessionFinder = find.text('Séance Push Réalisée');
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(sessionFinder, findsOneWidget);
    });

    testWidgets('Should display empty message when history is empty', (WidgetTester tester) async {
      mockWorkoutRepo.history.clear();
      await workoutProvider.init();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Aucun entraînement enregistré'), findsOneWidget);
    });
  });
}
