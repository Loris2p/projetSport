import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/workout_session.dart';
import '../models/personal_record.dart';

abstract class WorkoutRepository {
  Future<void> init();
  Future<void> setUserId(String? userId);
  List<Exercise> getExercises();
  Future<void> saveExercise(Exercise exercise);
  Future<void> deleteExercise(String id);

  List<WorkoutProgram> getPrograms();
  Future<void> saveProgram(WorkoutProgram program);
  Future<void> deleteProgram(String id);

  List<WorkoutSession> getHistory();
  Future<void> saveSession(WorkoutSession session);
  Future<void> deleteSession(String id);

  List<PersonalRecord> getPersonalRecords();
  Future<void> savePersonalRecord(PersonalRecord record);
  Future<void> deletePersonalRecord(String exerciseId);
}


