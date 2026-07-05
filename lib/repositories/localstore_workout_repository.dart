import 'package:flutter/foundation.dart';
import 'package:localstore/localstore.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_session.dart';
import 'workout_repository.dart';

class LocalstoreWorkoutRepository implements WorkoutRepository {
  final _db = Localstore.instance;
  String? _userId;

  List<Exercise> _exercises = [];
  List<WorkoutProgram> _programs = [];
  List<WorkoutSession> _sessions = [];

  String get _exercisesCollection => _userId != null ? 'exercises_$_userId' : 'exercises';
  String get _programsCollection => _userId != null ? 'programs_$_userId' : 'programs';
  String get _sessionsCollection => _userId != null ? 'sessions_$_userId' : 'sessions';

  @override
  Future<void> init() async {
    await setUserId(null);
  }

  @override
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    try {
      await _loadFromLocalstore();
    } catch (e) {
      debugPrint("Erreur lors de l'initialisation de LocalstoreWorkoutRepository pour l'utilisateur $userId : $e");
    }
  }

  // Charge les données de Localstore en mémoire cache synchrone
  Future<void> _loadFromLocalstore() async {
    // 1. Charger les exercices (globaux de l'admin + personnels de l'utilisateur)
    final List<Exercise> loadedExercises = [];

    // Si l'utilisateur n'est pas l'administrateur, on charge d'abord les exercices globaux de l'admin
    if (_userId != 'admin_uid_global') {
      final globalExercisesMap = await _db.collection('exercises_admin_uid_global').get();
      if (globalExercisesMap != null && globalExercisesMap.isNotEmpty) {
        loadedExercises.addAll(
          globalExercisesMap.values
              .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList(),
        );
      }
    }

    // Charger les exercices personnels/custom de l'utilisateur actuel
    final userExercisesMap = await _db.collection(_exercisesCollection).get();
    if (userExercisesMap != null && userExercisesMap.isNotEmpty) {
      final userExercises = userExercisesMap.values
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      for (var ex in userExercises) {
        if (!loadedExercises.any((e) => e.id == ex.id)) {
          loadedExercises.add(ex);
        }
      }
    }

    _exercises = loadedExercises;

    // 2. Charger les programmes
    final programsMap = await _db.collection(_programsCollection).get();
    if (programsMap != null && programsMap.isNotEmpty) {
      _programs = programsMap.values
          .map((p) => WorkoutProgram.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    } else {
      _programs = [];
    }

    // 3. Charger les séances (histoire)
    final sessionsMap = await _db.collection(_sessionsCollection).get();
    if (sessionsMap != null && sessionsMap.isNotEmpty) {
      _sessions = sessionsMap.values
          .map((s) => WorkoutSession.fromJson(Map<String, dynamic>.from(s as Map)))
          .toList();
      // Trier par date décroissante (le plus récent en premier)
      _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    } else {
      _sessions = [];
    }
  }

  // --- API INTERFACE ---

  @override
  List<Exercise> getExercises() => _exercises;

  @override
  Future<void> saveExercise(Exercise exercise) async {
    final index = _exercises.indexWhere((e) => e.id == exercise.id);
    if (index >= 0) {
      _exercises[index] = exercise;
    } else {
      _exercises.add(exercise);
    }
    await _db.collection(_exercisesCollection).doc(exercise.id).set(exercise.toJson());
  }

  @override
  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    await _db.collection(_exercisesCollection).doc(id).delete();
  }

  @override
  List<WorkoutProgram> getPrograms() => _programs;

  @override
  Future<void> saveProgram(WorkoutProgram program) async {
    final index = _programs.indexWhere((p) => p.id == program.id);
    if (index >= 0) {
      _programs[index] = program;
    } else {
      _programs.add(program);
    }
    await _db.collection(_programsCollection).doc(program.id).set(program.toJson());
  }

  @override
  Future<void> deleteProgram(String id) async {
    _programs.removeWhere((p) => p.id == id);
    await _db.collection(_programsCollection).doc(id).delete();
  }

  @override
  List<WorkoutSession> getHistory() => _sessions;

  @override
  Future<void> saveSession(WorkoutSession session) async {
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      _sessions[index] = session;
    } else {
      _sessions.add(session);
    }
    // Maintenir le tri chronologique décroissant
    _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    await _db.collection(_sessionsCollection).doc(session.id).set(session.toJson());
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _db.collection(_sessionsCollection).doc(id).delete();
  }
}
