import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/models/user_profile.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/dashboard_screen.dart';
import '../helpers/mock_repositories.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('DashboardScreen Widget Tests', () {
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
      await workoutProvider.init();
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('Should render user greeting, stats, and action buttons', (WidgetTester tester) async {
      mockAuthRepo.currentUser = UserProfile(
        uid: 'u1',
        email: 'user@example.com',
        displayName: 'Jean',
      );
      await authProvider.init();

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Bonjour, Jean !'), findsOneWidget);
      expect(find.text('STATISTIQUES HEBDOMADAIRES (7j)'), findsOneWidget);
      expect(find.text('Nouvelle Séance Vide'), findsOneWidget);
    });

    testWidgets('Should start active session when tapping Nouvelle Séance Vide', (WidgetTester tester) async {
      try {
        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(workoutProvider.activeSession, isNull);

        await tester.tap(find.text('Nouvelle Séance Vide'));
        await tester.pumpAndSettle();

        expect(workoutProvider.activeSession, isNotNull);
      } finally {
        workoutProvider.cancelActiveSession();
      }
    });
  });
}
