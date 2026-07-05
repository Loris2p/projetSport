import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/performed_exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_session.dart';
import '../repositories/workout_repository.dart';
import '../services/health_sync_service.dart';

class WorkoutProvider with ChangeNotifier {
  final WorkoutRepository repository;
  final HealthSyncService healthSyncService;
  final _uuid = const Uuid();

  List<Exercise> _exercises = [];
  List<WorkoutProgram> _programs = [];
  List<WorkoutSession> _history = [];

  WorkoutSession? _activeSession;
  bool _isLoading = true;

  // Rest Timer State
  int _restTimerDuration = 90; // Default 90s
  Timer? _timer;
  bool _isRestTimerActive = false;

  // Active Session Duration Timer
  Timer? _sessionDurationTimer;

  // ValueNotifiers to avoid calling notifyListeners() on global provider every second
  final ValueNotifier<Duration> sessionDurationNotifier = ValueNotifier<Duration>(Duration.zero);
  final ValueNotifier<int> restTimerRemainingNotifier = ValueNotifier<int>(0);

  // Memory cache for session volumes and PRs to avoid heavy rebuild/scroll lookups
  final Map<String, double> _sessionVolumeCache = {};
  final Map<String, List<Map<String, dynamic>>> _sessionPRsCache = {};

  // Memory caches for menu performance
  List<dynamic> _flatHistory = [];
  double _weeklyVolume = 0.0;
  int _weeklyWorkoutsCount = 0;
  final Map<String, String> _sessionExercisesSummaryCache = {};

  WorkoutProvider({
    required this.repository,
    required this.healthSyncService,
  });

  // Getters
  List<Exercise> get exercises => _exercises;
  List<WorkoutProgram> get programs => _programs;
  List<WorkoutSession> get history => _history;
  WorkoutSession? get activeSession => _activeSession;
  bool get isLoading => _isLoading;

  List<dynamic> get flatHistory => _flatHistory;
  double get weeklyVolume => _weeklyVolume;
  int get weeklyWorkoutsCount => _weeklyWorkoutsCount;

  int get restTimerDuration => _restTimerDuration;
  int get restTimerRemaining => restTimerRemainingNotifier.value;
  bool get isRestTimerActive => _isRestTimerActive;
  Duration get sessionDuration => sessionDurationNotifier.value;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await repository.init();
    _exercises = repository.getExercises();
    _programs = repository.getPrograms();
    _history = repository.getHistory();

    _updateWeeklyStatsAndFlatHistory();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUser(String? userId) async {
    _isLoading = true;
    notifyListeners();

    await repository.setUserId(userId);
    _exercises = repository.getExercises();
    _programs = repository.getPrograms();
    _history = repository.getHistory();

    // Vider les caches mémoire lors du changement d'utilisateur
    _sessionVolumeCache.clear();
    _sessionPRsCache.clear();
    _sessionExercisesSummaryCache.clear();

    _updateWeeklyStatsAndFlatHistory();

    _isLoading = false;
    notifyListeners();
  }

  // --- Exercises ---
  Future<void> createCustomExercise(String name, String category, {String? notes}) async {
    final newExercise = Exercise(
      id: 'custom_${_uuid.v4()}',
      name: name,
      category: category,
      notes: notes,
      isCustom: true,
    );
    await repository.saveExercise(newExercise);
    _exercises = repository.getExercises();
    notifyListeners();
  }

  Future<void> updateExercise(Exercise exercise) async {
    await repository.saveExercise(exercise);
    _exercises = repository.getExercises();
    _sessionExercisesSummaryCache.clear();
    _sessionPRsCache.clear();
    _updateWeeklyStatsAndFlatHistory();
    notifyListeners();
  }

  Future<void> deleteExercise(String id) async {
    await repository.deleteExercise(id);
    _exercises = repository.getExercises();
    _sessionExercisesSummaryCache.clear();
    _sessionPRsCache.clear();
    _updateWeeklyStatsAndFlatHistory();
    notifyListeners();
  }

  // --- Programs ---
  Future<void> createProgram(String name, String description, List<Exercise> exercises, [Map<String, String>? exerciseGroups]) async {
    final newProgram = WorkoutProgram(
      id: 'program_${_uuid.v4()}',
      name: name,
      description: description,
      exercises: exercises,
      exerciseGroups: exerciseGroups,
    );
    await repository.saveProgram(newProgram);
    _programs = repository.getPrograms();
    notifyListeners();
  }

  Future<void> updateProgram(WorkoutProgram program) async {
    await repository.saveProgram(program);
    _programs = repository.getPrograms();
    notifyListeners();
  }

  Future<void> deleteProgram(String id) async {
    await repository.deleteProgram(id);
    _programs = repository.getPrograms();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    await repository.deleteSession(id);
    _history = repository.getHistory();
    _sessionVolumeCache.remove(id);
    _sessionPRsCache.remove(id);
    _sessionExercisesSummaryCache.remove(id);
    _updateWeeklyStatsAndFlatHistory();
    notifyListeners();
  }

  // --- Active Session ---
  void startSession(WorkoutProgram? program, {String? customName}) {
    if (_activeSession != null) return;

    final String name = customName ?? (program != null ? program.name : "Séance Libre");
    final List<PerformedExercise> exercises = [];

    if (program != null) {
      for (var exercise in program.exercises) {
        final String? exerciseGroupId = program.exerciseGroups?[exercise.id];
        exercises.add(
          PerformedExercise(
            exerciseId: exercise.id,
            groupId: exerciseGroupId,
            sets: [
              ExerciseSet(id: _uuid.v4(), type: SetType.normal),
              ExerciseSet(id: _uuid.v4(), type: SetType.normal),
              ExerciseSet(id: _uuid.v4(), type: SetType.normal),
            ],
          ),
        );
      }
    }

    _activeSession = WorkoutSession(
      id: 'session_${_uuid.v4()}',
      programId: program?.id,
      name: name,
      startTime: DateTime.now(),
      exercises: exercises,
    );

    // Start global session duration timer
    sessionDurationNotifier.value = Duration.zero;
    _sessionDurationTimer?.cancel();
    _sessionDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeSession != null) {
        sessionDurationNotifier.value = DateTime.now().difference(_activeSession!.startTime);
      }
    });

    notifyListeners();
  }

  void addExerciseToActiveSession(Exercise exercise) {
    if (_activeSession == null) return;
    
    // Check if exercise already added
    final exists = _activeSession!.exercises.any((e) => e.exerciseId == exercise.id);
    if (exists) return;

    _activeSession!.exercises.add(
      PerformedExercise(
        exerciseId: exercise.id,
        sets: [
          ExerciseSet(id: _uuid.v4(), type: SetType.normal),
        ],
      ),
    );
    notifyListeners();
  }

  void removeExerciseFromActiveSession(String exerciseId) {
    if (_activeSession == null) return;
    _activeSession!.exercises.removeWhere((e) => e.exerciseId == exerciseId);
    notifyListeners();
  }

  void reorderExercisesInActiveSession(int oldIndex, int newIndex) {
    if (_activeSession == null) return;
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _activeSession!.exercises.removeAt(oldIndex);
    _activeSession!.exercises.insert(newIndex, item);
    notifyListeners();
  }

  void setExerciseGroup(PerformedExercise perfEx, String? groupId) {
    if (_activeSession == null) return;
    final index = _activeSession!.exercises.indexOf(perfEx);
    if (index >= 0) {
      _activeSession!.exercises[index].groupId = groupId;
      _sessionExercisesSummaryCache.clear();
      _sessionPRsCache.clear();
      notifyListeners();
    }
  }

  void addSetToPerformedExercise(PerformedExercise perfEx) {
    if (_activeSession == null) return;
    final index = _activeSession!.exercises.indexOf(perfEx);
    if (index >= 0) {
      // Copy weight/reps from previous set if possible
      double defaultWeight = 0.0;
      int defaultReps = 0;
      SetType defaultType = SetType.normal;

      if (perfEx.sets.isNotEmpty) {
        final last = perfEx.sets.last;
        defaultWeight = last.weight;
        defaultReps = last.reps;
        defaultType = last.type;
      }

      perfEx.sets.add(
        ExerciseSet(
          id: _uuid.v4(),
          weight: defaultWeight,
          reps: defaultReps,
          type: defaultType,
        ),
      );
      notifyListeners();
    }
  }

  void removeSetFromPerformedExercise(PerformedExercise perfEx, String setId) {
    if (_activeSession == null) return;
    final index = _activeSession!.exercises.indexOf(perfEx);
    if (index >= 0) {
      perfEx.sets.removeWhere((s) => s.id == setId);
      notifyListeners();
    }
  }

  void updateSetMetrics(ExerciseSet set, double weight, int reps, {SetType? type}) {
    set.weight = weight;
    set.reps = reps;
    // If it was completed, recheck PRs
    if (set.isCompleted && _activeSession != null) {
      // Find the exercise ID
      String exerciseId = '';
      for (var ex in _activeSession!.exercises) {
        if (ex.sets.contains(set)) {
          exerciseId = ex.exerciseId;
          break;
        }
      }
      if (exerciseId.isNotEmpty) {
        checkPRsForSet(exerciseId, set);
      }
    }
    notifyListeners();
  }

  void updateSetType(ExerciseSet set, SetType type) {
    set.type = type;
    notifyListeners();
  }

  void updatePerformedExerciseNotes(PerformedExercise perfEx, String notes) {
    perfEx.notes = notes.isEmpty ? null : notes;
    notifyListeners();
  }

  void toggleSetCompletion(PerformedExercise perfEx, ExerciseSet set) {
    if (_activeSession == null) return;

    set.isCompleted = !set.isCompleted;

    if (set.isCompleted) {
      // Run PR detection
      checkPRsForSet(perfEx.exerciseId, set);
      // Start rest timer
      startRestTimer();
    } else {
      set.isWeightPR = false;
      set.is1RMPR = false;
    }

    notifyListeners();
  }

  void setRestTimerDuration(int seconds) {
    _restTimerDuration = seconds;
    if (_isRestTimerActive) {
      restTimerRemainingNotifier.value = seconds;
    }
    notifyListeners();
  }

  void startRestTimer([int? duration]) {
    _timer?.cancel();
    restTimerRemainingNotifier.value = duration ?? _restTimerDuration;
    _isRestTimerActive = true;
    notifyListeners();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (restTimerRemainingNotifier.value > 0) {
        restTimerRemainingNotifier.value--;
      } else {
        stopRestTimer();
      }
    });
  }

  void stopRestTimer() {
    _timer?.cancel();
    _isRestTimerActive = false;
    restTimerRemainingNotifier.value = 0;
    notifyListeners();
  }

  void cancelActiveSession() {
    _activeSession = null;
    _sessionDurationTimer?.cancel();
    sessionDurationNotifier.value = Duration.zero;
    stopRestTimer();
    notifyListeners();
  }

  Future<void> finishActiveSession() async {
    if (_activeSession == null) return;

    final endTime = DateTime.now();

    // Filter exercises that have at least one completed set
    final completedExercises = _activeSession!.exercises
        .map((perfEx) {
          final completedSets = perfEx.sets.where((s) => s.isCompleted).toList();
          if (completedSets.isEmpty) return null;
          return PerformedExercise(
            exerciseId: perfEx.exerciseId,
            sets: completedSets,
            notes: perfEx.notes,
          );
        })
        .whereType<PerformedExercise>()
        .toList();

    if (completedExercises.isEmpty) {
      // No completed sets, just cancel
      cancelActiveSession();
      return;
    }

    // Load health metrics (average heart rate and calories) for session duration
    double? activeCalories;
    double? heartRate;
    try {
      final metrics = await healthSyncService.fetchMetrics(
        startTime: _activeSession!.startTime,
        endTime: endTime,
      );
      activeCalories = metrics['activeCaloriesBurned'];
      heartRate = metrics['averageHeartRate'];
    } catch (e) {
      debugPrint("Erreur de récupération des métriques de santé: $e");
    }

    final finalSession = WorkoutSession(
      id: _activeSession!.id,
      programId: _activeSession!.programId,
      name: _activeSession!.name,
      startTime: _activeSession!.startTime,
      endTime: endTime,
      exercises: completedExercises,
      activeCaloriesBurned: activeCalories,
      averageHeartRate: heartRate,
    );

    // Save locally
    await repository.saveSession(finalSession);
    _history = repository.getHistory();

    // Write to health kit / Health Connect
    try {
      await healthSyncService.writeWorkout(
        startTime: finalSession.startTime,
        endTime: endTime,
        activityName: finalSession.name,
        calories: activeCalories,
      );
    } catch (e) {
      debugPrint("Erreur d'écriture dans le Health Store: $e");
    }

    // Clean up
    if (finalSession.id.isNotEmpty) {
      _sessionVolumeCache.remove(finalSession.id);
      _sessionPRsCache.remove(finalSession.id);
      _sessionExercisesSummaryCache.remove(finalSession.id);
    }
    _activeSession = null;
    _sessionDurationTimer?.cancel();
    sessionDurationNotifier.value = Duration.zero;
    stopRestTimer();
    _updateWeeklyStatsAndFlatHistory();
    notifyListeners();
  }

  // --- PR Detection Engine ---
  void checkPRsForSet(String exerciseId, ExerciseSet set) {
    if (!set.isCompleted) {
      set.isWeightPR = false;
      set.is1RMPR = false;
      return;
    }

    double bestWeight = 0.0;
    double best1RM = 0.0;

    // Scan history
    for (var session in _history) {
      for (var perfEx in session.exercises) {
        if (perfEx.exerciseId == exerciseId) {
          for (var s in perfEx.sets) {
            if (s.isCompleted) {
              if (s.weight > bestWeight) {
                bestWeight = s.weight;
              }
              if (s.estimated1RM > best1RM) {
                best1RM = s.estimated1RM;
              }
            }
          }
        }
      }
    }

    // Scan current session (excluding this set itself)
    if (_activeSession != null) {
      for (var perfEx in _activeSession!.exercises) {
        if (perfEx.exerciseId == exerciseId) {
          for (var s in perfEx.sets) {
            if (s.isCompleted && s.id != set.id) {
              if (s.weight > bestWeight) {
                bestWeight = s.weight;
              }
              if (s.estimated1RM > best1RM) {
                best1RM = s.estimated1RM;
              }
            }
          }
        }
      }
    }

    // Set PR flags
    set.isWeightPR = set.weight > 0 && (bestWeight == 0 || set.weight > bestWeight);
    set.is1RMPR = set.estimated1RM > 0 && (best1RM == 0 || set.estimated1RM > best1RM);
  }

  // Calculate volume of a session (using memory cache)
  double calculateSessionVolume(WorkoutSession session) {
    if (_sessionVolumeCache.containsKey(session.id)) {
      return _sessionVolumeCache[session.id]!;
    }
    double volume = 0;
    for (var perfEx in session.exercises) {
      for (var s in perfEx.sets) {
        if (s.isCompleted) {
          volume += s.weight * s.reps;
        }
      }
    }
    _sessionVolumeCache[session.id] = volume;
    return volume;
  }

  // Calculate total volume for the last 7 days
  double getWeeklyVolume() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    double volume = 0;
    for (var session in _history) {
      if (session.startTime.isAfter(sevenDaysAgo)) {
        volume += calculateSessionVolume(session);
      }
    }
    return volume;
  }

  // Calculate workouts count in the last 7 days
  int getWeeklyWorkoutsCount() {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    return _history.where((s) => s.startTime.isAfter(sevenDaysAgo)).length;
  }

  // Get all PRs broken in a specific session (using memory cache)
  List<Map<String, dynamic>> getSessionPRs(WorkoutSession session) {
    if (_sessionPRsCache.containsKey(session.id)) {
      return _sessionPRsCache[session.id]!;
    }
    final List<Map<String, dynamic>> prList = [];
    for (var perfEx in session.exercises) {
      final exercise = _exercises.firstWhere((e) => e.id == perfEx.exerciseId, 
          orElse: () => Exercise(id: perfEx.exerciseId, name: 'Exercice Inconnu', category: 'Inconnue'));
      
      bool hasWeightPR = false;
      bool has1RMPR = false;
      double maxWeight = 0;
      double max1RM = 0;

      for (var s in perfEx.sets) {
        if (s.isCompleted) {
          if (s.isWeightPR) {
            hasWeightPR = true;
            if (s.weight > maxWeight) maxWeight = s.weight;
          }
          if (s.is1RMPR) {
            has1RMPR = true;
            if (s.estimated1RM > max1RM) max1RM = s.estimated1RM;
          }
        }
      }

      if (hasWeightPR || has1RMPR) {
        prList.add({
          'exercise': exercise,
          'weightPR': hasWeightPR ? maxWeight : null,
          'oneRepMaxPR': has1RMPR ? max1RM : null,
        });
      }
    }
    _sessionPRsCache[session.id] = prList;
    return prList;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionDurationTimer?.cancel();
    sessionDurationNotifier.dispose();
    restTimerRemainingNotifier.dispose();
    super.dispose();
  }

  // Helper to re-calculate stats and cached flat lists
  void _updateWeeklyStatsAndFlatHistory() {
    // 1. Flat history list
    final List<dynamic> flatList = [];
    String? currentMonthYear;
    for (var session in _history) {
      final String monthYear = DateFormat('MMMM yyyy', 'fr_FR').format(session.startTime);
      final String capitalized = monthYear[0].toUpperCase() + monthYear.substring(1);
      if (capitalized != currentMonthYear) {
        currentMonthYear = capitalized;
        flatList.add(capitalized);
      }
      flatList.add(session);
    }
    _flatHistory = flatList;

    // 2. Weekly stats
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    double volume = 0;
    int count = 0;
    for (var session in _history) {
      if (session.startTime.isAfter(sevenDaysAgo)) {
        volume += calculateSessionVolume(session);
        count++;
      }
    }
    _weeklyVolume = volume;
    _weeklyWorkoutsCount = count;
  }

  // Get exercise names as summary (using memory cache)
  String getSessionExercisesSummary(WorkoutSession session) {
    if (_sessionExercisesSummaryCache.containsKey(session.id)) {
      return _sessionExercisesSummaryCache[session.id]!;
    }
    final String summary = session.exercises.map((pe) {
      final ex = _exercises.firstWhere((e) => e.id == pe.exerciseId,
          orElse: () => Exercise(id: pe.exerciseId, name: 'Exercice', category: 'Inconnue'));
      return ex.name;
    }).join(', ');
    _sessionExercisesSummaryCache[session.id] = summary;
    return summary;
  }
}
