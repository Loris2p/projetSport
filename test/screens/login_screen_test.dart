import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/login_screen.dart';
import 'package:sport_app/services/health_sync_service.dart';
import '../helpers/mock_repositories.dart';

void main() {
  group('LoginScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepo;
    late MockWorkoutRepository mockWorkoutRepo;
    late AuthProvider authProvider;
    late WorkoutProvider workoutProvider;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      mockWorkoutRepo = MockWorkoutRepository();
      authProvider = AuthProvider(authRepository: mockAuthRepo);
      workoutProvider = WorkoutProvider(
        repository: mockWorkoutRepo,
        healthSyncService: MockHealthSyncService(),
      );
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
        ],
        child: const MaterialApp(
          home: LoginScreen(),
        ),
      );
    }

    testWidgets('Should display login form by default', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('SPORTILIFE'), findsOneWidget);
      expect(find.text('Connexion'), findsOneWidget);
      expect(find.text('Adresse email'), findsOneWidget);
      expect(find.text('Mot de passe'), findsOneWidget);
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('Should toggle between login and sign up mode', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final toggleButton = find.text("Vous n'avez pas de compte ? S'inscrire");
      expect(toggleButton, findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.text('Créer un compte'), findsOneWidget);
      expect(find.text('Nom complet'), findsOneWidget);
      expect(find.text("S'enregistrer"), findsOneWidget);
    });

    testWidgets('Should show validation error when submitting empty fields', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(find.text('Veuillez entrer votre email.'), findsOneWidget);
    });

    testWidgets('Should call signIn when submitting valid credentials', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'user@example.com');
      await tester.enterText(find.byType(TextFormField).last, 'password123');

      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.email, equals('user@example.com'));
    });
  });
}
