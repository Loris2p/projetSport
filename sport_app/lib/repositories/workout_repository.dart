import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_session.dart';

abstract class WorkoutRepository {
  Future<void> init();
  List<Exercise> getExercises();
  Future<void> saveExercise(Exercise exercise);
  Future<void> deleteExercise(String id);

  List<WorkoutProgram> getPrograms();
  Future<void> saveProgram(WorkoutProgram program);
  Future<void> deleteProgram(String id);

  List<WorkoutSession> getHistory();
  Future<void> saveSession(WorkoutSession session);
  Future<void> deleteSession(String id);
}

class LocalJsonWorkoutRepository implements WorkoutRepository {
  List<Exercise> _exercises = [];
  List<WorkoutProgram> _programs = [];
  List<WorkoutSession> _sessions = [];

  final List<Exercise> _defaultExercises = [
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
      await _loadExercises();
      await _loadPrograms();
      await _loadSessions();
    } catch (e) {
      // Gérer l'erreur ou réinitialiser avec des listes vides
      debugPrint("Erreur d'initialisation du dépôt local : $e");
    }
  }

  Future<File> _getFile(String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$filename');
  }

  Future<void> _loadExercises() async {
    try {
      final file = await _getFile('custom_exercises.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        final custom = jsonList.map((e) => Exercise.fromJson(e as Map<String, dynamic>)).toList();
        _exercises = [..._defaultExercises, ...custom];
      } else {
        _exercises = [..._defaultExercises];
      }
    } catch (e) {
      _exercises = [..._defaultExercises];
    }
  }

  Future<void> _loadPrograms() async {
    try {
      final file = await _getFile('programs.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _programs = jsonList.map((e) => WorkoutProgram.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        _programs = _getInitialDefaultPrograms();
        await _saveProgramsToFile();
      }
    } catch (e) {
      _programs = _getInitialDefaultPrograms();
    }
  }

  Future<void> _loadSessions() async {
    try {
      final file = await _getFile('history.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _sessions = jsonList.map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>)).toList();
        // Trier par date décroissante (plus récent en premier)
        _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
      } else {
        _sessions = [];
      }
    } catch (e) {
      _sessions = [];
    }
  }

  List<WorkoutProgram> _getInitialDefaultPrograms() {
    return [
      WorkoutProgram(
        id: 'prog_pbl_push',
        name: 'Push (Poussée)',
        description: 'Séance pectoraux, épaules, triceps',
        exercises: [
          _defaultExercises.firstWhere((e) => e.id == 'bench_press'),
          _defaultExercises.firstWhere((e) => e.id == 'overhead_press'),
          _defaultExercises.firstWhere((e) => e.id == 'incline_dumbell_press'),
          _defaultExercises.firstWhere((e) => e.id == 'lateral_raise'),
          _defaultExercises.firstWhere((e) => e.id == 'tricep_pushdown'),
        ],
      ),
      WorkoutProgram(
        id: 'prog_pbl_pull',
        name: 'Pull (Tirage)',
        description: 'Séance dos, biceps, abdominaux',
        exercises: [
          _defaultExercises.firstWhere((e) => e.id == 'deadlift'),
          _defaultExercises.firstWhere((e) => e.id == 'pull_up'),
          _defaultExercises.firstWhere((e) => e.id == 'lat_pulldown'),
          _defaultExercises.firstWhere((e) => e.id == 'bicep_curl'),
          _defaultExercises.firstWhere((e) => e.id == 'crunch'),
        ],
      ),
      WorkoutProgram(
        id: 'prog_pbl_legs',
        name: 'Legs (Jambes)',
        description: 'Séance bas du corps complète',
        exercises: [
          _defaultExercises.firstWhere((e) => e.id == 'squat'),
          _defaultExercises.firstWhere((e) => e.id == 'leg_press'),
        ],
      ),
    ];
  }

  Future<void> _saveExercisesToFile() async {
    final file = await _getFile('custom_exercises.json');
    final customList = _exercises.where((e) => e.isCustom).toList();
    final jsonContent = jsonEncode(customList.map((e) => e.toJson()).toList());
    await file.writeAsString(jsonContent);
  }

  Future<void> _saveProgramsToFile() async {
    final file = await _getFile('programs.json');
    final jsonContent = jsonEncode(_programs.map((p) => p.toJson()).toList());
    await file.writeAsString(jsonContent);
  }

  Future<void> _saveSessionsToFile() async {
    final file = await _getFile('history.json');
    final jsonContent = jsonEncode(_sessions.map((s) => s.toJson()).toList());
    await file.writeAsString(jsonContent);
  }

  // --- API ---

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
    await _saveExercisesToFile();
  }

  @override
  Future<void> deleteExercise(String id) async {
    _exercises.removeWhere((e) => e.id == id && e.isCustom);
    await _saveExercisesToFile();
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
    await _saveProgramsToFile();
  }

  @override
  Future<void> deleteProgram(String id) async {
    _programs.removeWhere((p) => p.id == id);
    await _saveProgramsToFile();
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
    // Trier de nouveau pour maintenir la cohérence chronologique
    _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    await _saveSessionsToFile();
  }

  @override
  Future<void> deleteSession(String id) async {
    _sessions.removeWhere((s) => s.id == id);
    await _saveSessionsToFile();
  }
}
