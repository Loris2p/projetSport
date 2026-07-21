import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/user_profile.dart';
import 'package:sport_app/providers/auth_provider.dart';
import '../helpers/mock_repositories.dart';

void main() {
  group('AuthProvider State Management Tests', () {
    late MockAuthRepository mockRepo;
    late AuthProvider authProvider;

    setUp(() {
      mockRepo = MockAuthRepository();
      authProvider = AuthProvider(authRepository: mockRepo);
    });

    test('Initial state should be unauthenticated and not loading', () {
      expect(authProvider.currentUser, isNull);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.isAdminTrainingMode, isFalse);
    });

    test('init() should fetch current user from repository', () async {
      final user = UserProfile(uid: 'u1', email: 'user@test.com', displayName: 'User Test');
      mockRepo.currentUser = user;

      await authProvider.init();

      expect(authProvider.currentUser, equals(user));
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.isLoading, isFalse);
    });

    test('signIn() success should set currentUser and clear error', () async {
      final success = await authProvider.signIn('user@test.com', 'password123');

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.email, equals('user@test.com'));
      expect(authProvider.errorMessage, isNull);
    });

    test('signIn() failure should set error message and return false', () async {
      mockRepo.shouldFail = true;
      mockRepo.errorMessage = 'Mot de passe incorrect.';

      final success = await authProvider.signIn('user@test.com', 'wrongpass');

      expect(success, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.errorMessage, equals('Mot de passe incorrect.'));
    });

    test('signUp() success should set currentUser', () async {
      final success = await authProvider.signUp('newuser@test.com', 'secret123', 'New User');

      expect(success, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.currentUser?.displayName, equals('New User'));
    });

    test('signOut() should clear currentUser', () async {
      await authProvider.signIn('user@test.com', 'password123');
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.signOut();
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.currentUser, isNull);
    });

    test('clearError() should clear error message', () async {
      mockRepo.shouldFail = true;
      await authProvider.signIn('invalid', 'pass');
      expect(authProvider.errorMessage, isNotNull);

      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });

    test('setAdminTrainingMode() should toggle admin training state', () {
      expect(authProvider.isAdminTrainingMode, isFalse);

      authProvider.setAdminTrainingMode(true);
      expect(authProvider.isAdminTrainingMode, isTrue);

      authProvider.setAdminTrainingMode(false);
      expect(authProvider.isAdminTrainingMode, isFalse);
    });

    test('getAllUsers(), deleteUser(), and updateUser() management', () async {
      await authProvider.signUp('admin@test.com', 'password123', 'Admin');

      final users = await authProvider.getAllUsers();
      expect(users.length, equals(1));

      final user = authProvider.currentUser!;
      final updatedUser = UserProfile(uid: user.uid, email: user.email, displayName: 'Super Admin', isAdmin: true);
      final updateResult = await authProvider.updateUser(updatedUser);
      expect(updateResult, isTrue);
      expect(authProvider.currentUser?.displayName, equals('Super Admin'));

      final deleteResult = await authProvider.deleteUser(user.uid);
      expect(deleteResult, isTrue);
      expect((await authProvider.getAllUsers()), isEmpty);
    });
  });
}
