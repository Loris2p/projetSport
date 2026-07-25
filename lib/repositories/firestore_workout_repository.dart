import 'package:flutter/foundation.dart' show debugPrint;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_session.dart';
import '../models/personal_record.dart';
import 'workout_repository.dart';

class FirestoreWorkoutRepository implements WorkoutRepository {
  fb_store.FirebaseFirestore get _firestore => fb_store.FirebaseFirestore.instance;
  String? _userId;

  List<Exercise> _exercises = [];
  List<WorkoutProgram> _programs = [];
  List<WorkoutSession> _sessions = [];
  List<PersonalRecord> _records = [];

  @override
  Future<void> init() async {
    await setUserId(null);
  }

  @override
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    try {
      await _loadFromFirestore();
    } catch (e) {
      debugPrint("Erreur lors de l'initialisation de FirestoreWorkoutRepository pour l'utilisateur $userId : $e");
    }
  }

  // Charge les données de Firestore en cache synchrone
  Future<void> _loadFromFirestore() async {
    if (_userId == null) {
      _exercises = [];
      _programs = [];
      _sessions = [];
      _records = [];
      return;
    }

    final List<Exercise> loadedExercises = [];

    // 1. Charger les exercices (globaux de l'admin + personnels de l'utilisateur)
    // Exercices publics (isCustom == false)
    final publicQuery = await _firestore
        .collection('exercises')
        .where('isCustom', isEqualTo: false)
        .get();

    loadedExercises.addAll(
      publicQuery.docs
          .map((doc) => Exercise.fromJson(doc.data()))
          .toList(),
    );

    // Si l'utilisateur n'est pas l'administrateur par défaut, charger également ses exercices personnalisés
    if (_userId != 'admin_uid_global') {
      final privateQuery = await _firestore
          .collection('exercises')
          .where('isCustom', isEqualTo: true)
          .where('ownerId', isEqualTo: _userId)
          .get();

      final privateExercises = privateQuery.docs
          .map((doc) => Exercise.fromJson(doc.data()))
          .toList();

      for (var ex in privateExercises) {
        if (!loadedExercises.any((e) => e.id == ex.id)) {
          loadedExercises.add(ex);
        }
      }
    }

    _exercises = loadedExercises;

    // 2. Charger les programmes
    final programsQuery = await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('programs')
        .get();

    _programs = programsQuery.docs
        .map((doc) => WorkoutProgram.fromJson(doc.data()))
        .toList();

    // 3. Charger les séances (historique)
    final sessionsQuery = await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('sessions')
        .orderBy('startTime', descending: true)
        .get();

    _sessions = sessionsQuery.docs
        .map((doc) => WorkoutSession.fromJson(doc.data()))
        .toList();

    // 4. Charger les records personnels (PRs)
    final recordsQuery = await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('records')
        .get();

    _records = recordsQuery.docs
        .map((doc) => PersonalRecord.fromJson(doc.data()))
        .toList();
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

    final data = exercise.toJson();
    data['ownerId'] = _userId;

    await _firestore
        .collection('exercises')
        .doc(exercise.id)
        .set(data, fb_store.SetOptions(merge: true));
  }

  @override
  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id);
    await _firestore.collection('exercises').doc(id).delete();
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

    await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('programs')
        .doc(program.id)
        .set(program.toJson(), fb_store.SetOptions(merge: true));
  }

  @override
  Future<void> deleteProgram(String id) async {
    _programs.removeWhere((p) => p.id == id);
    await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('programs')
        .doc(id)
        .delete();
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
    _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('sessions')
        .doc(session.id)
        .set(session.toJson(), fb_store.SetOptions(merge: true));
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('sessions')
        .doc(id)
        .delete();
  }

  @override
  List<PersonalRecord> getPersonalRecords() => _records;

  @override
  Future<void> savePersonalRecord(PersonalRecord record) async {
    final index = _records.indexWhere((r) => r.exerciseId == record.exerciseId);
    if (index >= 0) {
      _records[index] = record;
    } else {
      _records.add(record);
    }

    await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('records')
        .doc(record.exerciseId)
        .set(record.toJson(), fb_store.SetOptions(merge: true));
  }

  @override
  Future<void> deletePersonalRecord(String exerciseId) async {
    _records.removeWhere((r) => r.exerciseId == exerciseId);
    await _firestore
        .collection('users')
        .doc(_userId!)
        .collection('records')
        .doc(exerciseId)
        .delete();
  }
}

