import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<void> init();
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> signIn(String email, String password);
  Future<UserProfile> signUp(String email, String password, String name, {DateTime? birthDate});
  Future<void> signOut();
  Future<List<UserProfile>> getAllUsers();
  Future<void> deleteUser(String uid);
  Future<void> updateUser(UserProfile user);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<bool> isEmailVerified();
  Future<void> changePassword({required String currentPassword, required String newPassword});
  Future<void> updateEmail({required String currentPassword, required String newEmail});
  Future<void> reloadUser();
}

