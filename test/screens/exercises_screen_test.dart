import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/models/exercise.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/exercises_screen.dart';
import '../helpers/mock_repositories.dart';

void main() {
  group('ExercisesScreen Widget Tests', () {
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

      mockWorkoutRepo.exercises.add(
        Exercise(id: 'ex_1', name: 'Développé Couché', categories: ['Pectoraux']),
      );
      mockWorkoutRepo.exercises.add(
        Exercise(id: 'ex_2', name: 'Traction', categories: ['Dos']),
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
          home: ExercisesScreen(),
        ),
      );
    }

    testWidgets('Should display exercises list and filter by search query', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Exercices'), findsOneWidget);
      expect(find.widgetWithText(Card, 'Développé Couché'), findsOneWidget);
      expect(find.widgetWithText(Card, 'Traction'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Traction');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(Card, 'Développé Couché'), findsNothing);
      expect(find.widgetWithText(Card, 'Traction'), findsOneWidget);
    });

    testWidgets('Should open creation dialog when tapping floating action button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Nouvel Exercice'), findsOneWidget);
      expect(find.text('Nom de l\'exercice'), findsOneWidget);
    });
  });
}
