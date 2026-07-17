import 'exercise_set.dart';
import 'exercise_type.dart';

class PerformedExercise {
  final String exerciseId;
  final ExerciseType type;
  final List<ExerciseSet> sets;
  String? notes; 
  String? groupId;

  PerformedExercise({
    required this.exerciseId,
    this.type = ExerciseType.reps,
    required this.sets,
    this.notes,
    this.groupId,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'type': type.name,
      'sets': sets.map((s) => s.toJson()).toList(),
      'notes': notes,
      'groupId': groupId,
    };
  }

  factory PerformedExercise.fromJson(Map<String, dynamic> json) {
    return PerformedExercise(
      exerciseId: json['exerciseId'] as String,
      type: ExerciseType.fromString(json['type'] as String?),
      sets: (json['sets'] as List<dynamic>)
          .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      groupId: json['groupId'] as String?,
    );
  }
}

