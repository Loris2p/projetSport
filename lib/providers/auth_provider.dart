import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository authRepository;
  UserProfile? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdminTrainingMode = false;
  bool _isEmailVerified = false;

  // Rate Limiting Client pour protection anti-force brute
  int _failedLoginAttempts = 0;
  DateTime? _lockoutUntil;
  Timer? _lockoutTimer;

  AuthProvider({required this.authRepository});

  // Getters
  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAdminTrainingMode => _isAdminTrainingMode;
  bool get isEmailVerifiedState => _isEmailVerified;

  bool get isLockedOut {
    if (_lockoutUntil == null) return false;
    final now = DateTime.now();
    if (now.isBefore(_lockoutUntil!)) {
      return true;
    }
    _lockoutUntil = null;
    _failedLoginAttempts = 0;
    return false;
  }

  int get remainingLockoutSeconds {
    if (_lockoutUntil == null) return 0;
    final remaining = _lockoutUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  void setAdminTrainingMode(bool value) {
    _isAdminTrainingMode = value;
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.init();
      _currentUser = await authRepository.getCurrentUser();
      if (_currentUser != null) {
        _isEmailVerified = await authRepository.isEmailVerified();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (isLockedOut) {
      _errorMessage = "Trop de tentatives échouées. Réessayez dans $remainingLockoutSeconds secondes.";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await authRepository.signIn(email, password);
      _failedLoginAttempts = 0;
      _lockoutUntil = null;
      _lockoutTimer?.cancel();
      _isEmailVerified = await authRepository.isEmailVerified();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _failedLoginAttempts++;
      if (_failedLoginAttempts >= 5) {
        _lockoutUntil = DateTime.now().add(const Duration(seconds: 30));
        _startLockoutCountdown();
        _errorMessage = "Compte temporairement bloqué suite à 5 tentatives échouées. Réessayez dans 30 secondes.";
      } else {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
      }
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isLockedOut) {
        timer.cancel();
        _errorMessage = null;
      }
      notifyListeners();
    });
  }

  Future<bool> signUp(String email, String password, String name, {DateTime? birthDate}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await authRepository.signUp(email, password, name, birthDate: birthDate);
      _isEmailVerified = false;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.sendPasswordResetEmail(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendEmailVerification() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.sendEmailVerification();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkEmailVerified() async {
    try {
      _isEmailVerified = await authRepository.isEmailVerified();
      notifyListeners();
      return _isEmailVerified;
    } catch (_) {
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEmail(String currentPassword, String newEmail) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.updateEmail(
        currentPassword: currentPassword,
        newEmail: newEmail,
      );
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(email: newEmail.trim().toLowerCase());
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await authRepository.signOut();
      _currentUser = null;
      _isEmailVerified = false;
      _failedLoginAttempts = 0;
      _lockoutUntil = null;
      _lockoutTimer?.cancel();
    } catch (e) {
      debugPrint("Erreur lors de la déconnexion : $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  Future<List<UserProfile>> getAllUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await authRepository.getAllUsers();
      _isLoading = false;
      notifyListeners();
      return list;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return [];
    }
  }

  Future<bool> deleteUser(String uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.deleteUser(uid);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(UserProfile user) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.updateUser(user);
      if (_currentUser?.uid == user.uid) {
        _currentUser = user;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}

