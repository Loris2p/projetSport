import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/main_shell.dart';
import '../helpers/mock_repositories.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('MainShell Widget Tests', () {
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
          home: MainShell(),
        ),
      );
    }

    testWidgets('Should display bottom navigation items and switch tabs on tap', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Tableau de bord'), findsOneWidget);
      expect(find.text('Programmes'), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Exercices'), findsOneWidget);

      // Switch to Programmes tab
      await tester.tap(find.text('Programmes'));
      await tester.pumpAndSettle();

      // Switch to Exercices tab
      await tester.tap(find.text('Exercices'));
      await tester.pumpAndSettle();
      expect(find.text('Exercices'), findsWidgets);
    });

    testWidgets('Should display floating active workout bar when active session exists', (WidgetTester tester) async {
      try {
        workoutProvider.startSession(null, customName: 'Séance Active En Cours');

        await tester.pumpWidget(createWidgetUnderTest());
        await tester.pumpAndSettle();

        expect(find.text('Séance Active En Cours'), findsOneWidget);
        expect(find.textContaining('Entraînement en cours'), findsOneWidget);
      } finally {
        workoutProvider.cancelActiveSession();
      }
    });
  });
}
