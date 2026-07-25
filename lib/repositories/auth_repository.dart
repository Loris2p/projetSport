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
}

