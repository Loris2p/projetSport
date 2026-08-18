import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/performed_exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_session.dart';
import '../models/program_exercise.dart';
import '../models/personal_record.dart';
import '../models/body_measurement.dart';
import '../repositories/workout_repository.dart';
import '../services/notification_service.dart';

class WorkoutProvider with ChangeNotifier, WidgetsBindingObserver {
  final WorkoutRepository repository;
  final _uuid = const Uuid();

  List<Exercise> _exercises = [];
  List<WorkoutProgram> _programs = [];
  List<WorkoutSession> _history = [];
  List<PersonalRecord> _personalRecords = [];
  List<BodyMeasurement> _bodyMeasurements = [];
  String? _favoriteProgramId;
  String? _currentUserId;

  WorkoutSession? _activeSession;
  bool _isLoading = true;

  // Rest Timer State
  int _restTimerDuration = 90; // Default 90s
  Timer? _timer;
  DateTime? _restTimerEndTime;
  bool _isRestTimerActive = false;
  final NotificationService _notificationService = NotificationService();

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
  }) {
    WidgetsBinding.instance.addObserver(this);
    _notificationService.init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isRestTimerActive && _restTimerEndTime != null) {
      _checkRestTimerState();
    }
  }

  void _checkRestTimerState() {
    if (!_isRestTimerActive || _restTimerEndTime == null) return;

    final remaining = _restTimerEndTime!.difference(DateTime.now()).inSeconds;
    if (remaining <= 0) {
      _onRestTimerCompleted();
    } else {
      restTimerRemainingNotifier.value = remaining;
      _notificationService.updateRestTimerNotification(
        remainingSeconds: remaining,
        endTime: _restTimerEndTime!,
      );
    }
  }

  // Getters
  List<Exercise> get exercises => _exercises;
  List<WorkoutProgram> get programs => _programs;
  List<WorkoutSession> get history => _history;
  List<PersonalRecord> get personalRecords => _personalRecords;
  List<BodyMeasurement> get bodyMeasurements => _bodyMeasurements;
  BodyMeasurement? get latestBodyMeasurement => _bodyMeasurements.isNotEmpty ? _bodyMeasurements.first : null;
  WorkoutSession? get activeSession => _activeSession;
  bool get isLoading => _isLoading;
  String? get favoriteProgramId => _favoriteProgramId;

  WorkoutProgram? get quickProgram {
    if (_programs.isEmpty) return null;
    if (_favoriteProgramId != null) {
      return _programs.firstWhere(
        (p) => p.id == _favoriteProgramId,
        orElse: () => _programs.first,
      );
    }
    return _programs.first;
  }

  Future<void> setFavoriteProgramId(String? programId) async {
    _favoriteProgramId = programId;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _currentUserId ?? 'guest';
      if (programId != null) {
        await prefs.setString('favorite_program_id_$uid', programId);
      } else {
        await prefs.remove('favorite_program_id_$uid');
      }
    } catch (e) {
      debugPrint("Erreur lors de la sauvegarde du programme favori: $e");
    }
  }

  Future<void> _loadFavoriteProgramId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = _currentUserId ?? 'guest';
      _favoriteProgramId = prefs.getString('favorite_program_id_$uid');
    } catch (e) {
      debugPrint("Erreur lors du chargement du programme favori: $e");
    }
  }

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
    await _loadFavoriteProgramId();
    _exercises = repository.getExercises();
    _programs = repository.getPrograms();
    _history = repository.getHistory();
    _personalRecords = repository.getPersonalRecords();
    _bodyMeasurements = repository.getBodyMeasurements();

    _updateWeeklyStatsAndFlatHistory();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadUser(String? userId) async {
    _isLoading = true;
    notifyListeners();

    _currentUserId = userId;
    await repository.setUserId(userId);
    await _loadFavoriteProgramId();
    _exercises = repository.getExercises();
    _programs = repository.getPrograms();
    _history = repository.getHistory();
    _personalRecords = repository.getPersonalRecords();
    _bodyMeasurements = repository.getBodyMeasurements();

    // Vider les caches mémoire lors du changement d'utilisateur
    _sessionVolumeCache.clear();
    _sessionPRsCache.clear();
    _sessionExercisesSummaryCache.clear();

    _updateWeeklyStatsAndFlatHistory();

    _isLoading = false;
    notifyListeners();
  }

  // --- Exercises ---
  Future<void> createCustomExercise(String name, {List<String>? categories, String? category, String? equipment, String? notes, String? videoUrl}) async {
    final newExercise = Exercise(
      id: 'custom_${_uuid.v4()}',
      name: name,
      categories: categories ?? (category != null && category.isNotEmpty ? [category] : ['Pectoraux']),
      equipment: equipment,
      notes: notes,
      videoUrl: videoUrl,
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
  Future<void> createProgram(String name, String description, List<ProgramExercise> exercises, [Map<String, String>? exerciseGroups]) async {
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

  Future<void> updateSession(WorkoutSession session) async {
    await repository.saveSession(session);
    _history = repository.getHistory();
    _sessionVolumeCache.remove(session.id);
    _sessionPRsCache.remove(session.id);
    _sessionExercisesSummaryCache.remove(session.id);
    _updateWeeklyStatsAndFlatHistory();
    notifyListeners();
  }

  Future<void> deleteSession(String id) async {
    WorkoutSession? sessionToDelete;
    try {
      sessionToDelete = _history.firstWhere((s) => s.id == id);
    } catch (_) {}

    await repository.deleteSession(id);
    _history = repository.getHistory();
    _sessionVolumeCache.remove(id);
    _sessionPRsCache.remove(id);
    _sessionExercisesSummaryCache.remove(id);

    if (sessionToDelete != null) {
      for (var perfEx in sessionToDelete.exercises) {
        await _recalculatePersonalRecordForExercise(perfEx.exerciseId);
      }
    }

    _updateWeeklyStatsAndFlatHistory();
    notifyListeners();
  }

  // --- Body Measurements ---
  Future<void> saveBodyMeasurement(BodyMeasurement measurement) async {
    await repository.saveBodyMeasurement(measurement);
    _bodyMeasurements = repository.getBodyMeasurements();
    notifyListeners();
  }

  Future<void> deleteBodyMeasurement(String id) async {
    await repository.deleteBodyMeasurement(id);
    _bodyMeasurements = repository.getBodyMeasurements();
    notifyListeners();
  }

  // --- Active Session ---
  void startSession(WorkoutProgram? program, {String? customName}) {
    if (_activeSession != null) return;

    final String name = customName ?? (program != null ? program.name : "Séance Libre");
    final List<PerformedExercise> exercises = [];

    if (program != null) {
      for (var exercise in program.exercises) {
        final String? exerciseGroupId = exercise.groupId ?? program.exerciseGroups?[exercise.exerciseId];
        final List<ExerciseSet> generatedSets;
        if (exercise.customSets != null && exercise.customSets!.isNotEmpty) {
          generatedSets = exercise.customSets!
              .map((cs) => ExerciseSet(
                    id: _uuid.v4(),
                    type: cs.type,
                    weight: cs.weight,
                    reps: cs.reps,
                    duration: cs.duration,
                    distance: cs.distance,
                    speed: cs.speed,
                    incline: cs.incline,
                    tempo: cs.tempo,
                    workTime: cs.workTime,
                    intervalRest: cs.intervalRest,
                  ))
              .toList();
        } else {
          generatedSets = List.generate(
            exercise.setsCount,
            (_) => ExerciseSet(
              id: _uuid.v4(),
              type: SetType.normal,
              reps: exercise.repsCount,
              duration: exercise.durationTarget,
              distance: exercise.distanceTarget,
              speed: exercise.speedTarget,
              incline: exercise.inclineTarget,
              tempo: exercise.tempoCode,
              workTime: exercise.workTime,
              intervalRest: exercise.intervalRestTime,
            ),
          );
        }

        exercises.add(
          PerformedExercise(
            exerciseId: exercise.exerciseId,
            groupId: exerciseGroupId,
            type: exercise.type,
            sets: generatedSets,
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
        type: ExerciseType.reps,
        sets: [
          ExerciseSet(id: _uuid.v4(), type: SetType.normal),
        ],
      ),
    );
    notifyListeners();
  }

  void updateActiveSessionExerciseType(dynamic target, ExerciseType type) {
    if (_activeSession == null) return;
    int index = -1;
    if (target is PerformedExercise) {
      index = _activeSession!.exercises.indexOf(target);
    } else if (target is String) {
      index = _activeSession!.exercises.indexWhere((e) => e.exerciseId == target);
    }
    if (index >= 0) {
      final oldPerfEx = _activeSession!.exercises[index];
      _activeSession!.exercises[index] = PerformedExercise(
        exerciseId: oldPerfEx.exerciseId,
        type: type,
        sets: oldPerfEx.sets,
        notes: oldPerfEx.notes,
        groupId: oldPerfEx.groupId,
      );
      notifyListeners();
    }
  }

  void removeExerciseFromActiveSession(dynamic target) {
    if (_activeSession == null) return;
    if (target is PerformedExercise) {
      _activeSession!.exercises.remove(target);
    } else if (target is String) {
      _activeSession!.exercises.removeWhere((e) => e.exerciseId == target);
    } else if (target is int) {
      if (target >= 0 && target < _activeSession!.exercises.length) {
        _activeSession!.exercises.removeAt(target);
      }
    }
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
      if (perfEx.sets.isNotEmpty) {
        final last = perfEx.sets.last;
        perfEx.sets.add(
          ExerciseSet(
            id: _uuid.v4(),
            weight: 0.0,
            reps: 0,
            duration: last.duration,
            distance: last.distance,
            speed: last.speed,
            incline: last.incline,
            tempo: last.tempo,
            workTime: last.workTime,
            intervalRest: last.intervalRest,
            type: last.type,
          ),
        );
      } else {
        perfEx.sets.add(
          ExerciseSet(
            id: _uuid.v4(),
            type: SetType.normal,
          ),
        );
      }
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

  void updateSetMetrics(
    ExerciseSet set,
    double weight,
    int reps, {
    SetType? type,
    int? duration,
    double? distance,
    double? speed,
    double? incline,
  }) {
    set.weight = weight;
    set.reps = reps;
    if (duration != null) set.duration = duration;
    if (distance != null) set.distance = distance;
    if (speed != null) set.speed = speed;
    if (incline != null) set.incline = incline;
    if (type != null) set.type = type;
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
      // Start rest timer using exercise custom rest duration if available
      int? restTime;
      if (_activeSession?.programId != null) {
        try {
          final program = _programs.firstWhere((p) => p.id == _activeSession!.programId);
          for (var pe in program.exercises) {
            if (pe.exerciseId == perfEx.exerciseId) {
              restTime = pe.restTime;
              break;
            }
          }
        } catch (_) {}
      }
      startRestTimer(restTime);
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
    if (duration != null && duration > 0) {
      _restTimerDuration = duration;
    }
    final startDuration = duration ?? _restTimerDuration;
    _restTimerEndTime = DateTime.now().add(Duration(seconds: startDuration));
    restTimerRemainingNotifier.value = startDuration;
    _isRestTimerActive = true;
    notifyListeners();

    _notificationService.updateRestTimerNotification(
      remainingSeconds: startDuration,
      endTime: _restTimerEndTime!,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkRestTimerState();
    });
  }

  void adjustRestTimer(int deltaSeconds) {
    if (!_isRestTimerActive || _restTimerEndTime == null) return;

    final currentRemaining = restTimerRemainingNotifier.value;
    final newRemaining = (currentRemaining + deltaSeconds).clamp(1, 3600);
    final diff = newRemaining - currentRemaining;

    _restTimerEndTime = DateTime.now().add(Duration(seconds: newRemaining));
    _restTimerDuration = (_restTimerDuration + diff).clamp(1, 3600);
    restTimerRemainingNotifier.value = newRemaining;
    notifyListeners();

    _notificationService.updateRestTimerNotification(
      remainingSeconds: newRemaining,
      endTime: _restTimerEndTime!,
    );
  }

  void _onRestTimerCompleted() {
    _timer?.cancel();
    _isRestTimerActive = false;
    _restTimerEndTime = null;
    restTimerRemainingNotifier.value = 0;
    notifyListeners();

    _notificationService.notifyRestFinished();
  }

  void stopRestTimer() {
    _timer?.cancel();
    _isRestTimerActive = false;
    _restTimerEndTime = null;
    restTimerRemainingNotifier.value = 0;
    notifyListeners();

    _notificationService.cancelRestTimerNotification();
  }

  void cancelActiveSession() {
    _activeSession = null;
    _sessionDurationTimer?.cancel();
    sessionDurationNotifier.value = Duration.zero;
    stopRestTimer();
    notifyListeners();
  }

  Future<WorkoutSession?> finishActiveSession() async {
    if (_activeSession == null) return null;

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
      return null;
    }

    final finalSession = WorkoutSession(
      id: _activeSession!.id,
      programId: _activeSession!.programId,
      name: _activeSession!.name,
      startTime: _activeSession!.startTime,
      endTime: endTime,
      exercises: completedExercises,
    );

    // Save locally and in Firestore
    await repository.saveSession(finalSession);
    _history = repository.getHistory();

    // Update Personal Records in Firestore
    for (var perfEx in completedExercises) {
      final String exId = perfEx.exerciseId;
      PersonalRecord existingRec = _personalRecords.firstWhere(
        (r) => r.exerciseId == exId,
        orElse: () => PersonalRecord(exerciseId: exId),
      );

      double newMaxW = existingRec.maxWeight;
      DateTime? newMaxWDate = existingRec.maxWeightDate;
      double newMax1RM = existingRec.max1RM;
      DateTime? newMax1RMDate = existingRec.max1RMDate;
      bool updated = false;

      for (var s in perfEx.sets) {
        if (s.isCompleted) {
          if (s.weight > newMaxW) {
            newMaxW = s.weight;
            newMaxWDate = finalSession.startTime;
            updated = true;
          }
          if (s.estimated1RM > newMax1RM) {
            newMax1RM = s.estimated1RM;
            newMax1RMDate = finalSession.startTime;
            updated = true;
          }
        }
      }

      if (updated) {
        final updatedRec = existingRec.copyWith(
          maxWeight: newMaxW,
          maxWeightDate: newMaxWDate,
          max1RM: newMax1RM,
          max1RMDate: newMax1RMDate,
          updatedAt: DateTime.now(),
        );
        await repository.savePersonalRecord(updatedRec);
      }
    }
    _personalRecords = repository.getPersonalRecords();

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
    return finalSession;
  }

  // --- PR Detection Engine ---
  void checkPRsForSet(String exerciseId, ExerciseSet set) {
    if (!set.isCompleted) {
      set.isWeightPR = false;
      set.is1RMPR = false;
      return;
    }

    PersonalRecord? record;
    try {
      record = _personalRecords.firstWhere((r) => r.exerciseId == exerciseId);
    } catch (_) {}

    double bestWeight = record?.maxWeight ?? 0.0;
    double best1RM = record?.max1RM ?? 0.0;

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

  Future<void> _recalculatePersonalRecordForExercise(String exerciseId) async {
    double maxW = 0.0;
    DateTime? maxWDate;
    double max1RM = 0.0;
    DateTime? max1RMDate;

    for (var session in _history) {
      for (var perfEx in session.exercises) {
        if (perfEx.exerciseId == exerciseId) {
          for (var s in perfEx.sets) {
            if (s.isCompleted) {
              if (s.weight > maxW) {
                maxW = s.weight;
                maxWDate = session.startTime;
              }
              if (s.estimated1RM > max1RM) {
                max1RM = s.estimated1RM;
                max1RMDate = session.startTime;
              }
            }
          }
        }
      }
    }

    if (maxW > 0 || max1RM > 0) {
      final rec = PersonalRecord(
        exerciseId: exerciseId,
        maxWeight: maxW,
        maxWeightDate: maxWDate,
        max1RM: max1RM,
        max1RMDate: max1RMDate,
        updatedAt: DateTime.now(),
      );
      await repository.savePersonalRecord(rec);
    } else {
      await repository.deletePersonalRecord(exerciseId);
    }
    _personalRecords = repository.getPersonalRecords();
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
    WidgetsBinding.instance.removeObserver(this);
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

  /// Returns all sessions performed on a given date (ignoring time)
  List<WorkoutSession> getSessionsForDate(DateTime date) {
    return _history.where((session) {
      return session.startTime.year == date.year &&
          session.startTime.month == date.month &&
          session.startTime.day == date.day;
    }).toList();
  }

  /// Check if a specific date has at least one workout session
  bool hasSessionOnDate(DateTime date) {
    return _history.any((session) =>
        session.startTime.year == date.year &&
        session.startTime.month == date.month &&
        session.startTime.day == date.day);
  }

  /// Calculates current consecutive days with completed workouts
  int get currentStreak {
    if (_history.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    bool workedOutToday = hasSessionOnDate(today);
    bool workedOutYesterday = hasSessionOnDate(yesterday);

    if (!workedOutToday && !workedOutYesterday) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = workedOutToday ? today : yesterday;

    while (hasSessionOnDate(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Count unique days with completed workouts in a given month/year
  int getActiveDaysCountForMonth(int year, int month) {
    final Set<int> uniqueDays = {};
    for (var session in _history) {
      if (session.startTime.year == year && session.startTime.month == month) {
        uniqueDays.add(session.startTime.day);
      }
    }
    return uniqueDays.length;
  }
}

