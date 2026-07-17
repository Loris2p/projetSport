import 'exercise_type.dart';

class ProgramExercise {
  final String exerciseId;
  final ExerciseType type;
  final int setsCount;
  final int repsCount;
  final int restTime; // Temps de repos en secondes
  final int durationTarget; // Temps cible en secondes (pour les exercices de type temps)
  final double distanceTarget; // Distance cible en km (pour les exercices de type distance)

  ProgramExercise({
    required this.exerciseId,
    this.type = ExerciseType.reps,
    required this.setsCount,
    required this.repsCount,
    required this.restTime,
    this.durationTarget = 0,
    this.distanceTarget = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'type': type.name,
      'setsCount': setsCount,
      'repsCount': repsCount,
      'restTime': restTime,
      'durationTarget': durationTarget,
      'distanceTarget': distanceTarget,
    };
  }

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      exerciseId: json['exerciseId'] as String,
      type: ExerciseType.fromString(json['type'] as String?),
      setsCount: json['setsCount'] as int,
      repsCount: json['repsCount'] as int,
      restTime: json['restTime'] as int,
      durationTarget: json['durationTarget'] as int? ?? 0,
      distanceTarget: (json['distanceTarget'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

