import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sport_app/models/user_profile.dart';
import 'package:sport_app/providers/auth_provider.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/screens/admin_screen.dart';
import '../helpers/mock_repositories.dart';

void main() {
  group('AdminScreen Widget Tests', () {
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

      final adminUser = UserProfile(uid: 'admin_1', email: 'admin@test.com', displayName: 'Admin User', isAdmin: true);
      mockAuthRepo.users.add(adminUser);
      mockAuthRepo.currentUser = adminUser;
      await authProvider.init();
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
        ],
        child: const MaterialApp(
          home: AdminScreen(),
        ),
      );
    }

    testWidgets('Should display user management list for admin', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Administration'), findsOneWidget);
      expect(find.text('Admin User'), findsOneWidget);
    });
  });
}
