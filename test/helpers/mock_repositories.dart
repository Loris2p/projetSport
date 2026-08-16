import 'package:sport_app/models/exercise.dart';
import 'package:sport_app/models/user_profile.dart';
import 'package:sport_app/models/workout_program.dart';
import 'package:sport_app/models/workout_session.dart';
import 'package:sport_app/models/personal_record.dart';
import 'package:sport_app/models/body_measurement.dart';
import 'package:sport_app/repositories/auth_repository.dart';
import 'package:sport_app/repositories/workout_repository.dart';

class MockAuthRepository implements AuthRepository {
  final List<UserProfile> users = [];
  UserProfile? currentUser;
  bool shouldFail = false;
  String errorMessage = 'Auth error';
  bool emailVerified = false;
  final List<String> sentResetEmails = [];

  @override
  Future<void> init() async {}

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (shouldFail) throw Exception(errorMessage);
    return currentUser;
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    if (shouldFail) throw Exception(errorMessage);
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception("L'email et le mot de passe ne peuvent pas être vides.");
    }
    final user = users.firstWhere(
      (u) => u.email == email.trim().toLowerCase(),
      orElse: () => UserProfile(
        uid: 'user_${email.hashCode}',
        email: email.trim().toLowerCase(),
        displayName: 'Test User',
        isAdmin: email.contains('admin'),
      ),
    );
    currentUser = user;
    if (!users.any((u) => u.uid == user.uid)) {
      users.add(user);
    }
    return user;
  }

  @override
  Future<UserProfile> signUp(String email, String password, String name, {DateTime? birthDate}) async {
    if (shouldFail) throw Exception(errorMessage);
    if (email.trim().isEmpty || password.trim().isEmpty || name.trim().isEmpty) {
      throw Exception("Tous les champs sont obligatoires.");
    }
    if (users.any((u) => u.email == email.trim().toLowerCase())) {
      throw Exception("Cet email est déjà utilisé par un autre compte.");
    }
    if (password.length < 8) {
      throw Exception("Le mot de passe doit contenir au moins 8 caractères.");
    }
    final newUser = UserProfile(
      uid: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim().toLowerCase(),
      displayName: name.trim(),
      birthDate: birthDate,
      isAdmin: false,
    );
    users.add(newUser);
    currentUser = newUser;
    return newUser;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (shouldFail) throw Exception(errorMessage);
    if (email.trim().isEmpty) {
      throw Exception("Veuillez saisir votre adresse email.");
    }
    sentResetEmails.add(email.trim().toLowerCase());
  }

  @override
  Future<void> sendEmailVerification() async {
    if (shouldFail) throw Exception(errorMessage);
    if (currentUser == null) throw Exception("Aucun utilisateur connecté.");
  }

  @override
  Future<bool> isEmailVerified() async {
    if (shouldFail) throw Exception(errorMessage);
    return emailVerified;
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    if (shouldFail) throw Exception(errorMessage);
    if (currentUser == null) throw Exception("Aucun utilisateur connecté.");
    if (currentPassword == 'wrong_pass') throw Exception("Le mot de passe actuel est incorrect.");
    if (newPassword.length < 8) throw Exception("Le nouveau mot de passe est trop faible.");
  }

  @override
  Future<void> updateEmail({required String currentPassword, required String newEmail}) async {
    if (shouldFail) throw Exception(errorMessage);
    if (currentUser == null) throw Exception("Aucun utilisateur connecté.");
    if (currentPassword == 'wrong_pass') throw Exception("Le mot de passe actuel est incorrect.");
    currentUser = currentUser!.copyWith(email: newEmail.trim().toLowerCase());
  }

  @override
  Future<void> reloadUser() async {
    if (shouldFail) throw Exception(errorMessage);
  }

  @override
  Future<void> signOut() async {
    if (shouldFail) throw Exception(errorMessage);
    currentUser = null;
    emailVerified = false;
  }

  @override
  Future<List<UserProfile>> getAllUsers() async {
    if (shouldFail) throw Exception(errorMessage);
    return List.from(users);
  }

  @override
  Future<void> deleteUser(String uid) async {
    if (shouldFail) throw Exception(errorMessage);
    users.removeWhere((u) => u.uid == uid);
    if (currentUser?.uid == uid) {
      currentUser = null;
    }
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    if (shouldFail) throw Exception(errorMessage);
    final index = users.indexWhere((u) => u.uid == user.uid);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    if (currentUser?.uid == user.uid) {
      currentUser = user;
    }
  }
}


class MockWorkoutRepository implements WorkoutRepository {
  String? currentUserId;
  final List<Exercise> exercises = [];
  final List<WorkoutProgram> programs = [];
  final List<WorkoutSession> history = [];
  final List<PersonalRecord> personalRecords = [];
  final List<BodyMeasurement> bodyMeasurements = [];

  bool shouldFail = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> setUserId(String? userId) async {
    currentUserId = userId;
  }

  @override
  List<Exercise> getExercises() {
    return List.from(exercises);
  }

  @override
  Future<void> saveExercise(Exercise exercise) async {
    if (shouldFail) throw Exception('Save exercise failed');
    final index = exercises.indexWhere((e) => e.id == exercise.id);
    if (index >= 0) {
      exercises[index] = exercise;
    } else {
      exercises.add(exercise);
    }
  }

  @override
  Future<void> deleteExercise(String id) async {
    if (shouldFail) throw Exception('Delete exercise failed');
    exercises.removeWhere((e) => e.id == id);
  }

  @override
  List<WorkoutProgram> getPrograms() {
    return List.from(programs);
  }

  @override
  Future<void> saveProgram(WorkoutProgram program) async {
    if (shouldFail) throw Exception('Save program failed');
    final index = programs.indexWhere((p) => p.id == program.id);
    if (index >= 0) {
      programs[index] = program;
    } else {
      programs.add(program);
    }
  }

  @override
  Future<void> deleteProgram(String id) async {
    if (shouldFail) throw Exception('Delete program failed');
    programs.removeWhere((p) => p.id == id);
  }

  @override
  List<WorkoutSession> getHistory() {
    return List.from(history);
  }

  @override
  Future<void> saveSession(WorkoutSession session) async {
    if (shouldFail) throw Exception('Save session failed');
    final index = history.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      history[index] = session;
    } else {
      history.add(session);
    }
  }

  @override
  Future<void> deleteSession(String id) async {
    if (shouldFail) throw Exception('Delete session failed');
    history.removeWhere((s) => s.id == id);
  }

  @override
  List<PersonalRecord> getPersonalRecords() {
    return List.from(personalRecords);
  }

  @override
  Future<void> savePersonalRecord(PersonalRecord record) async {
    if (shouldFail) throw Exception('Save record failed');
    final index = personalRecords.indexWhere((r) => r.exerciseId == record.exerciseId);
    if (index >= 0) {
      personalRecords[index] = record;
    } else {
      personalRecords.add(record);
    }
  }

  @override
  Future<void> deletePersonalRecord(String exerciseId) async {
    if (shouldFail) throw Exception('Delete record failed');
    personalRecords.removeWhere((r) => r.exerciseId == exerciseId);
  }

  @override
  List<BodyMeasurement> getBodyMeasurements() {
    return List.from(bodyMeasurements);
  }

  @override
  Future<void> saveBodyMeasurement(BodyMeasurement measurement) async {
    if (shouldFail) throw Exception('Save measurement failed');
    final index = bodyMeasurements.indexWhere((m) => m.id == measurement.id);
    if (index >= 0) {
      bodyMeasurements[index] = measurement;
    } else {
      bodyMeasurements.add(measurement);
    }
    bodyMeasurements.sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> deleteBodyMeasurement(String id) async {
    if (shouldFail) throw Exception('Delete measurement failed');
    bodyMeasurements.removeWhere((m) => m.id == id);
  }
}
