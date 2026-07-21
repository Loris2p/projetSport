import 'package:flutter_test/flutter_test.dart';
import 'package:sport_app/models/user_profile.dart';
import '../helpers/mock_repositories.dart';

void main() {
  group('AuthRepository Contract & Specifications Tests', () {
    late MockAuthRepository authRepo;

    setUp(() {
      authRepo = MockAuthRepository();
    });

    test('Should throw exception when signing in with empty fields', () async {
      expect(() => authRepo.signIn('', 'password'), throwsA(isA<Exception>()));
      expect(() => authRepo.signIn('email@test.com', ''), throwsA(isA<Exception>()));
    });

    test('Should sign in existing or new user and update current user', () async {
      final user = await authRepo.signIn('user@example.com', 'secret123');
      expect(user.email, equals('user@example.com'));
      expect(authRepo.currentUser?.email, equals('user@example.com'));

      final currentUser = await authRepo.getCurrentUser();
      expect(currentUser?.email, equals('user@example.com'));
    });

    test('Should throw exception when signing up with weak password (< 6 chars)', () async {
      expect(
        () => authRepo.signUp('new@example.com', '123', 'New User'),
        throwsA(predicate((e) => e.toString().contains('trop faible'))),
      );
    });

    test('Should throw exception when signing up with already registered email', () async {
      await authRepo.signUp('unique@example.com', 'password123', 'User 1');

      expect(
        () => authRepo.signUp('unique@example.com', 'password123', 'User 2'),
        throwsA(predicate((e) => e.toString().contains('déjà utilisé'))),
      );
    });

    test('Should successfully sign up user and retain profile', () async {
      final user = await authRepo.signUp('fresh@example.com', 'password123', 'Fresh User');
      expect(user.email, equals('fresh@example.com'));
      expect(user.displayName, equals('Fresh User'));
      expect(user.isAdmin, isFalse);

      final usersList = await authRepo.getAllUsers();
      expect(usersList.any((u) => u.email == 'fresh@example.com'), isTrue);
    });

    test('Should sign out user and set currentUser to null', () async {
      await authRepo.signIn('user@example.com', 'secret123');
      expect(authRepo.currentUser, isNotNull);

      await authRepo.signOut();
      expect(authRepo.currentUser, isNull);
      expect(await authRepo.getCurrentUser(), isNull);
    });

    test('Should update user profile details', () async {
      final user = await authRepo.signUp('update@example.com', 'password123', 'Original Name');
      final updatedProfile = UserProfile(
        uid: user.uid,
        email: user.email,
        displayName: 'Updated Name',
        isAdmin: true,
      );

      await authRepo.updateUser(updatedProfile);

      final users = await authRepo.getAllUsers();
      final fetched = users.firstWhere((u) => u.uid == user.uid);
      expect(fetched.displayName, equals('Updated Name'));
      expect(fetched.isAdmin, isTrue);
    });

    test('Should delete user profile from repository', () async {
      final user = await authRepo.signUp('delete@example.com', 'password123', 'Delete Me');
      expect((await authRepo.getAllUsers()).length, equals(1));

      await authRepo.deleteUser(user.uid);
      expect((await authRepo.getAllUsers()).length, equals(0));
      expect(authRepo.currentUser, isNull);
    });
  });
}
