import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sport_app/models/exercise.dart';
import 'package:sport_app/models/exercise_set.dart';
import 'package:sport_app/models/performed_exercise.dart';
import 'package:sport_app/models/program_exercise.dart';
import 'package:sport_app/models/workout_program.dart';
import 'package:sport_app/models/workout_session.dart';
import 'package:sport_app/providers/workout_provider.dart';
import 'package:sport_app/services/health_sync_service.dart';
import '../helpers/mock_repositories.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('fr_FR', null);
  });

  group('WorkoutProvider Comprehensive State Management Tests', () {
    late MockWorkoutRepository mockRepo;
    late MockHealthSyncService mockHealthSync;
    late WorkoutProvider provider;

    setUp(() {
      mockRepo = MockWorkoutRepository();
      mockHealthSync = MockHealthSyncService();
      provider = WorkoutProvider(
        repository: mockRepo,
        healthSyncService: mockHealthSync,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('init() should load exercises, programs and history from repository', () async {
      final sampleEx = Exercise(id: 'ex_1', name: 'Développé Couché', categories: ['Pectoraux']);
      final sampleProg = WorkoutProgram(id: 'p1', name: 'Push', description: '', exercises: []);
      final sampleSess = WorkoutSession(id: 's1', name: 'Séance 1', startTime: DateTime.now(), exercises: []);

      mockRepo.exercises.add(sampleEx);
      mockRepo.programs.add(sampleProg);
      mockRepo.history.add(sampleSess);

      await provider.init();

      expect(provider.isLoading, isFalse);
      expect(provider.exercises.length, equals(1));
      expect(provider.programs.length, equals(1));
      expect(provider.history.length, equals(1));
    });

    test('loadUser() should update userId in repo and refresh cached data', () async {
      await provider.init();
      await provider.loadUser('user_999');

      expect(mockRepo.currentUserId, equals('user_999'));
      expect(provider.isLoading, isFalse);
    });

    group('Exercise CRUD Operations', () {
      test('createCustomExercise() should add custom exercise', () async {
        await provider.init();

        await provider.createCustomExercise(
          'Dips Lestés',
          categories: ['Pectoraux', 'Triceps'],
          notes: 'Leste 20kg',
          videoUrl: 'https://youtube.com',
        );

        expect(provider.exercises.length, equals(1));
        final created = provider.exercises.first;
        expect(created.name, equals('Dips Lestés'));
        expect(created.isCustom, isTrue);
        expect(created.categories, equals(['Pectoraux', 'Triceps']));
      });

      test('updateExercise() and deleteExercise()', () async {
        await provider.init();
        await provider.createCustomExercise('Squat');
        final created = provider.exercises.first;

        final updated = Exercise(
          id: created.id,
          name: 'Squat Gobelet',
          categories: ['Jambes'],
          isCustom: true,
        );

        await provider.updateExercise(updated);
        expect(provider.exercises.first.name, equals('Squat Gobelet'));

        await provider.deleteExercise(created.id);
        expect(provider.exercises, isEmpty);
      });
    });

    group('Program CRUD Operations', () {
      test('createProgram(), updateProgram(), deleteProgram()', () async {
        await provider.init();

        final pe = ProgramExercise(
          exerciseId: 'ex_bench',
          setsCount: 4,
          repsCount: 10,
          restTime: 90,
        );

        await provider.createProgram('Push Day', 'Programme Pectoraux', [pe]);
        expect(provider.programs.length, equals(1));

        final program = provider.programs.first;
        expect(program.name, equals('Push Day'));

        final updatedProgram = WorkoutProgram(
          id: program.id,
          name: 'Push Day Advanced',
          description: 'Intensif',
          exercises: [pe],
        );
        await provider.updateProgram(updatedProgram);
        expect(provider.programs.first.name, equals('Push Day Advanced'));

        await provider.deleteProgram(program.id);
        expect(provider.programs, isEmpty);
      });
    });

    group('Active Session Operations', () {
      test('startSession() should initialize active session', () async {
        await provider.init();
        expect(provider.activeSession, isNull);

        provider.startSession(null, customName: 'Ma Séance Perso');
        expect(provider.activeSession, isNotNull);
        expect(provider.activeSession?.name, equals('Ma Séance Perso'));
        expect(provider.activeSession?.exercises, isEmpty);
      });

      test('startSession() from WorkoutProgram should populate default sets', () async {
        await provider.init();
        final program = WorkoutProgram(
          id: 'p1',
          name: 'Programme Test',
          description: '',
          exercises: [
            ProgramExercise(exerciseId: 'ex_bench', setsCount: 3, repsCount: 8, restTime: 90),
          ],
        );

        provider.startSession(program);

        final active = provider.activeSession;
        expect(active, isNotNull);
        expect(active?.exercises.length, equals(1));

        final perfEx = active!.exercises.first;
        expect(perfEx.exerciseId, equals('ex_bench'));
        expect(perfEx.sets.length, equals(3));
        expect(perfEx.sets.first.reps, equals(8));
      });

      test('addExerciseToActiveSession() and removeExerciseFromActiveSession()', () async {
        await provider.init();
        provider.startSession(null);

        final exercise = Exercise(id: 'ex_bench', name: 'Bench Press', categories: ['Pectoraux']);
        provider.addExerciseToActiveSession(exercise);

        expect(provider.activeSession?.exercises.length, equals(1));

        // Adding duplicate exercise should be ignored
        provider.addExerciseToActiveSession(exercise);
        expect(provider.activeSession?.exercises.length, equals(1));

        provider.removeExerciseFromActiveSession('ex_bench');
        expect(provider.activeSession?.exercises, isEmpty);
      });

      test('reorderExercisesInActiveSession()', () async {
        await provider.init();
        provider.startSession(null);

        final ex1 = Exercise(id: 'ex_1', name: 'Ex 1', categories: ['Pectoraux']);
        final ex2 = Exercise(id: 'ex_2', name: 'Ex 2', categories: ['Dos']);
        provider.addExerciseToActiveSession(ex1);
        provider.addExerciseToActiveSession(ex2);

        expect(provider.activeSession?.exercises.first.exerciseId, equals('ex_1'));

        provider.reorderExercisesInActiveSession(0, 2);
        expect(provider.activeSession?.exercises.first.exerciseId, equals('ex_2'));
      });

      test('addSetToPerformedExercise() should copy metrics from previous set', () async {
        await provider.init();
        provider.startSession(null);
        final ex = Exercise(id: 'ex_1', name: 'Ex 1', categories: ['Pectoraux']);
        provider.addExerciseToActiveSession(ex);

        final perfEx = provider.activeSession!.exercises.first;
        provider.updateSetMetrics(perfEx.sets.first, 100.0, 10);

        provider.addSetToPerformedExercise(perfEx);
        expect(perfEx.sets.length, equals(2));
        expect(perfEx.sets.last.weight, equals(100.0));
        expect(perfEx.sets.last.reps, equals(10));
      });

      test('removeSetFromPerformedExercise()', () async {
        await provider.init();
        provider.startSession(null);
        final ex = Exercise(id: 'ex_1', name: 'Ex 1', categories: ['Pectoraux']);
        provider.addExerciseToActiveSession(ex);

        final perfEx = provider.activeSession!.exercises.first;
        final setId = perfEx.sets.first.id;

        provider.removeSetFromPerformedExercise(perfEx, setId);
        expect(perfEx.sets, isEmpty);
      });
    });

    group('PR Engine & Metrics Tests', () {
      test('toggleSetCompletion() should trigger PR detection for Weight and 1RM', () async {
        await provider.init();

        // Populate history with an existing record: 80kg x 10 reps (1RM = 106.66kg)
        final pastSession = WorkoutSession(
          id: 'past_1',
          name: 'Past Session',
          startTime: DateTime.now().subtract(const Duration(days: 2)),
          exercises: [
            PerformedExercise(
              exerciseId: 'ex_bench',
              sets: [ExerciseSet(id: 's_past', weight: 80.0, reps: 10, isCompleted: true)],
            ),
          ],
        );
        mockRepo.history.add(pastSession);
        await provider.init();

        // Start active session with 90kg x 10 reps (Weight PR & 1RM PR)
        provider.startSession(null);
        final bench = Exercise(id: 'ex_bench', name: 'Développé Couché', categories: ['Pectoraux']);
        provider.addExerciseToActiveSession(bench);

        final perfEx = provider.activeSession!.exercises.first;
        final currentSet = perfEx.sets.first;
        provider.updateSetMetrics(currentSet, 90.0, 10);

        expect(currentSet.isWeightPR, isFalse);
        expect(currentSet.is1RMPR, isFalse);

        provider.toggleSetCompletion(perfEx, currentSet);

        expect(currentSet.isCompleted, isTrue);
        expect(currentSet.isWeightPR, isTrue);
        expect(currentSet.is1RMPR, isTrue);

        // Toggle completion off should clear PR flags
        provider.toggleSetCompletion(perfEx, currentSet);
        expect(currentSet.isCompleted, isFalse);
        expect(currentSet.isWeightPR, isFalse);
        expect(currentSet.is1RMPR, isFalse);
      });
    });

    group('Rest Timer & Session Timer Tests', () {
      test('startRestTimer() and stopRestTimer() state management', () async {
        await provider.init();
        provider.setRestTimerDuration(60);

        expect(provider.restTimerDuration, equals(60));
        expect(provider.isRestTimerActive, isFalse);

        provider.startRestTimer(45);
        expect(provider.isRestTimerActive, isTrue);
        expect(provider.restTimerRemaining, equals(45));

        provider.stopRestTimer();
        expect(provider.isRestTimerActive, isFalse);
        expect(provider.restTimerRemaining, equals(0));
      });
    });

    group('Finish and Cancel Active Session', () {
      test('cancelActiveSession() should discard active session', () async {
        await provider.init();
        provider.startSession(null);
        expect(provider.activeSession, isNotNull);

        provider.cancelActiveSession();
        expect(provider.activeSession, isNull);
      });

      test('finishActiveSession() should filter uncompleted sets and persist valid session', () async {
        await provider.init();
        provider.startSession(null, customName: 'Session avec au moins une série validée');

        final bench = Exercise(id: 'ex_bench', name: 'Développé Couché', categories: ['Pectoraux']);
        provider.addExerciseToActiveSession(bench);

        final perfEx = provider.activeSession!.exercises.first;
        provider.updateSetMetrics(perfEx.sets.first, 80.0, 10);
        provider.toggleSetCompletion(perfEx, perfEx.sets.first);

        await provider.finishActiveSession();

        expect(provider.activeSession, isNull);
        expect(provider.history.length, equals(1));
        expect(provider.history.first.name, equals('Session avec au moins une série validée'));
        expect(provider.history.first.activeCaloriesBurned, isNotNull);
        expect(provider.history.first.averageHeartRate, isNotNull);
      });

      test('finishActiveSession() with no completed sets should cancel session', () async {
        await provider.init();
        provider.startSession(null, customName: 'Session Vide');

        final bench = Exercise(id: 'ex_bench', name: 'Développé Couché', categories: ['Pectoraux']);
        provider.addExerciseToActiveSession(bench);

        await provider.finishActiveSession();

        expect(provider.activeSession, isNull);
        expect(provider.history, isEmpty);
      });
    });

    group('Volume, Weekly Stats and History Formatting', () {
      test('calculateSessionVolume(), getWeeklyVolume() and getWeeklyWorkoutsCount()', () async {
        await provider.init();

        final recentSession = WorkoutSession(
          id: 'sess_recent',
          name: 'Session Récente',
          startTime: DateTime.now().subtract(const Duration(days: 1)),
          exercises: [
            PerformedExercise(
              exerciseId: 'ex_bench',
              sets: [
                ExerciseSet(id: 's1', weight: 100.0, reps: 10, isCompleted: true), // 1000kg
                ExerciseSet(id: 's2', weight: 100.0, reps: 5, isCompleted: true),  // 500kg
              ],
            ),
          ],
        );

        mockRepo.history.add(recentSession);
        await provider.init();

        final sessionVol = provider.calculateSessionVolume(recentSession);
        expect(sessionVol, equals(1500.0));

        expect(provider.weeklyVolume, equals(1500.0));
        expect(provider.weeklyWorkoutsCount, equals(1));
      });

      test('flatHistory should insert month headers correctly', () async {
        await provider.init();

        final sessionJuly = WorkoutSession(
          id: 's_jul',
          name: 'Session de Juillet',
          startTime: DateTime(2026, 7, 15, 10, 0),
          exercises: [],
        );

        mockRepo.history.add(sessionJuly);
        await provider.init();

        final flatList = provider.flatHistory;
        expect(flatList.isNotEmpty, isTrue);
        expect(flatList.first, isA<String>());
        expect(flatList.first.toString().toLowerCase(), contains('juillet'));
      });
    });
  });
}
