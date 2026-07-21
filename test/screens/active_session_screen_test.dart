import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/models/exercise.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/active_session_screen.dart';
import 'package:sport_app/services/health_sync_service.dart';
import '../helpers/mock_repositories.dart';

void main() {
  group('ActiveSessionScreen Widget Tests', () {
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
        healthSyncService: MockHealthSyncService(),
      );

      mockWorkoutRepo.exercises.add(
        Exercise(id: 'ex_bench', name: 'Développé Couché', categories: ['Pectoraux']),
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
          home: ActiveSessionScreen(),
        ),
      );
    }

    testWidgets('Should display empty active session message when no session in progress', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Aucune séance en cours'), findsOneWidget);
      expect(find.text('Démarrer une séance libre'), findsOneWidget);
    });

    testWidgets('Should display active session controls and exercise when session active', (WidgetTester tester) async {
      try {
        workoutProvider.startSession(null, customName: 'Séance Test');
        workoutProvider.addExerciseToActiveSession(workoutProvider.exercises.first);

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Séance Test'), findsOneWidget);
        expect(find.text('Développé Couché'), findsOneWidget);
        expect(find.text('Terminer'), findsOneWidget);
        expect(find.text('Annuler'), findsOneWidget);
      } finally {
        workoutProvider.cancelActiveSession();
      }
    });
  });
}
