import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:localstore/localstore.dart';
import 'package:path_provider/path_provider.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_session.dart';
import 'workout_repository.dart';

class LocalstoreWorkoutRepository implements WorkoutRepository {
  final _db = Localstore.instance;

  List<Exercise> _exercises = [];
  List<WorkoutProgram> _programs = [];
  List<WorkoutSession> _sessions = [];

  final List<Exercise> _initialDefaultExercises = [
    Exercise(id: 'bench_press', name: 'Développé Couché', category: 'Pectoraux', notes: 'Exercice de base pour les pectoraux'),
    Exercise(id: 'squat', name: 'Squat', category: 'Jambes', notes: 'Exercice roi pour le bas du corps'),
    Exercise(id: 'deadlift', name: 'Soulevé de Terre', category: 'Dos', notes: 'Exercice complet pour la chaîne postérieure'),
    Exercise(id: 'pull_up', name: 'Tractions', category: 'Dos', notes: 'Exercice poids du corps pour le dos'),
    Exercise(id: 'overhead_press', name: 'Développé Militaire', category: 'Épaules', notes: 'Développé barre debout pour les épaules'),
    Exercise(id: 'bicep_curl', name: 'Curl Biceps (Haltères)', category: 'Bras', notes: 'Curls alternés pour les biceps'),
    Exercise(id: 'tricep_pushdown', name: 'Extension Triceps (Poulie)', category: 'Bras', notes: 'Extension poulie haute pour les triceps'),
    Exercise(id: 'leg_press', name: 'Presse à Cuisses', category: 'Jambes', notes: 'Alternative au squat pour cibler les quadriceps'),
    Exercise(id: 'crunch', name: 'Crunches', category: 'Abdominaux', notes: 'Exercice de flexion pour les abdominaux'),
    Exercise(id: 'lat_pulldown', name: 'Tirage Vertical', category: 'Dos', notes: 'Tirage poitrine à la poulie haute'),
    Exercise(id: 'incline_dumbell_press', name: 'Développé Incliné (Haltères)', category: 'Pectoraux', notes: 'Cible le haut des pectoraux'),
    Exercise(id: 'lateral_raise', name: 'Élévations Latérales', category: 'Épaules', notes: 'Pour le faisceau moyen des épaules'),
  ];

  @override
  Future<void> init() async {
    try {
      await _migrateIfNeeded();
      await _loadFromLocalstore();
    } catch (e) {
      debugPrint("Erreur d'initialisation de LocalstoreWorkoutRepository : $e");
    }
  }

  Future<File> _getOldFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$filename');
  }

  // Effectue la migration si la base de données Localstore est complètement vide
  Future<void> _migrateIfNeeded() async {
    final exercisesMap = await _db.collection('exercises').get();
    
    // Si aucun exercice n'existe dans Localstore, on procède à la migration des anciennes données JSON
    if (exercisesMap == null || exercisesMap.isEmpty) {
      debugPrint("[Migration] Début de la migration des fichiers JSON vers Localstore...");

      // 1. MIGRATION DES EXERCICES
      List<Exercise> migratedExercises = [];
      try {
        final customFile = await _getOldFile('custom_exercises.json');
        List<Exercise> custom = [];
        if (await customFile.exists()) {
          final content = await customFile.readAsString();
          final List<dynamic> jsonList = jsonDecode(content);
          custom = jsonList.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
        }
        migratedExercises = [..._initialDefaultExercises, ...custom];
      } catch (e) {
        migratedExercises = [..._initialDefaultExercises];
      }

      // Sauvegarder dans Localstore
      for (var exercise in migratedExercises) {
        await _db.collection('exercises').doc(exercise.id).set(exercise.toJson());
      }
      debugPrint("[Migration] ${migratedExercises.length} exercices migrés.");

      // 2. MIGRATION DES PROGRAMMES
      List<WorkoutProgram> migratedPrograms = [];
      try {
        final programsFile = await _getOldFile('programs.json');
        if (await programsFile.exists()) {
          final content = await programsFile.readAsString();
          final List<dynamic> jsonList = jsonDecode(content);
          migratedPrograms = jsonList.map((e) => WorkoutProgram.fromJson(e as Map<String, dynamic>)).toList();
        } else {
          migratedPrograms = _getInitialDefaultPrograms();
        }
      } catch (e) {
        migratedPrograms = _getInitialDefaultPrograms();
      }

      for (var program in migratedPrograms) {
        await _db.collection('programs').doc(program.id).set(program.toJson());
      }
      debugPrint("[Migration] ${migratedPrograms.length} programmes migrés.");

      // 3. MIGRATION DE L'HISTORIQUE DES SÉANCES
      List<WorkoutSession> migratedSessions = [];
      try {
        final historyFile = await _getOldFile('history.json');
        if (await historyFile.exists()) {
          final content = await historyFile.readAsString();
          final List<dynamic> jsonList = jsonDecode(content);
          migratedSessions = jsonList.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>)).toList();
        }
      } catch (e) {
        debugPrint("[Migration] Erreur lors de la lecture de l'historique JSON : $e");
      }

      for (var session in migratedSessions) {
        await _db.collection('sessions').doc(session.id).set(session.toJson());
      }
      debugPrint("[Migration] ${migratedSessions.length} séances d'historique migrées.");
      debugPrint("[Migration] Migration terminée avec succès.");
    }
  }

  List<WorkoutProgram> _getInitialDefaultPrograms() {
    return [
      WorkoutProgram(
        id: 'prog_pbl_push',
        name: 'Push (Poussée)',
        description: 'Séance pectoraux, épaules, triceps',
        exercises: [
          _initialDefaultExercises.firstWhere((e) => e.id == 'bench_press'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'overhead_press'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'incline_dumbell_press'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'lateral_raise'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'tricep_pushdown'),
        ],
      ),
      WorkoutProgram(
        id: 'prog_pbl_pull',
        name: 'Pull (Tirage)',
        description: 'Séance dos, biceps, abdominaux',
        exercises: [
          _initialDefaultExercises.firstWhere((e) => e.id == 'deadlift'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'pull_up'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'lat_pulldown'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'bicep_curl'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'crunch'),
        ],
      ),
      WorkoutProgram(
        id: 'prog_pbl_legs',
        name: 'Legs (Jambes)',
        description: 'Séance bas du corps complète',
        exercises: [
          _initialDefaultExercises.firstWhere((e) => e.id == 'squat'),
          _initialDefaultExercises.firstWhere((e) => e.id == 'leg_press'),
        ],
      ),
    ];
  }

  // Charge les données de Localstore en mémoire cache synchrone
  Future<void> _loadFromLocalstore() async {
    // 1. Charger les exercices
    final exercisesMap = await _db.collection('exercises').get();
    if (exercisesMap != null && exercisesMap.isNotEmpty) {
      _exercises = exercisesMap.values
          .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else {
      // Sécurité si la base est vide d'une manière ou d'une autre
      _exercises = List.from(_initialDefaultExercises);
      for (var exercise in _exercises) {
        await _db.collection('exercises').doc(exercise.id).set(exercise.toJson());
      }
    }

    // 2. Charger les programmes
    final programsMap = await _db.collection('programs').get();
    if (programsMap != null && programsMap.isNotEmpty) {
      _programs = programsMap.values
          .map((p) => WorkoutProgram.fromJson(Map<String, dynamic>.from(p as Map)))
          .toList();
    } else {
      _programs = [];
    }

    // 3. Charger les séances (histoire)
    final sessionsMap = await _db.collection('sessions').get();
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
    await _db.collection('exercises').doc(exercise.id).set(exercise.toJson());
  }

  @override
  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id && e.isCustom);
    await _db.collection('exercises').doc(id).delete();
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
    await _db.collection('programs').doc(program.id).set(program.toJson());
  }

  @override
  Future<void> deleteProgram(String id) async {
    _programs.removeWhere((p) => p.id == id);
    await _db.collection('programs').doc(id).delete();
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
    await _db.collection('sessions').doc(session.id).set(session.toJson());
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _db.collection('sessions').doc(id).delete();
  }
}
