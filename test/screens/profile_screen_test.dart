import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/models/user_profile.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/profile_screen.dart';

import '../helpers/mock_repositories.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR', null);
  });

  group('ProfileScreen Widget Tests', () {
    late MockAuthRepository mockAuthRepo;
    late MockWorkoutRepository mockWorkoutRepo;
    late AuthProvider authProvider;
    late WorkoutProvider workoutProvider;

    setUp(() async {
      mockAuthRepo = MockAuthRepository();
      mockWorkoutRepo = MockWorkoutRepository();
      mockAuthRepo.currentUser = UserProfile(
        uid: 'user_123',
        email: 'test@example.com',
        displayName: 'Alex Smith',
        birthDate: DateTime(1995, 6, 15),
      );
      authProvider = AuthProvider(authRepository: mockAuthRepo);
      workoutProvider = WorkoutProvider(repository: mockWorkoutRepo);

      await authProvider.init();
      await workoutProvider.init();
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }

    testWidgets('Should display user info (Name, Email, Age)', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Mon Profil'), findsOneWidget);
      expect(find.text('Alex Smith'), findsNWidgets(2));
      expect(find.text('test@example.com'), findsNWidgets(2));
    });

    testWidgets('Should enable editing mode when edit icon tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      final editButton = find.byIcon(Icons.edit_outlined);
      expect(editButton, findsOneWidget);

      await tester.tap(editButton);
      await tester.pumpAndSettle();

      expect(find.text('Enregistrer les modifications'), findsOneWidget);
    });
  });
}
