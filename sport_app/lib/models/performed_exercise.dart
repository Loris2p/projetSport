import 'exercise_set.dart';

class PerformedExercise {
  final String exerciseId;
  final List<ExerciseSet> sets;
  String? notes; 

  PerformedExercise({
    required this.exerciseId,
    required this.sets,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'sets': sets.map((s) => s.toJson()).toList(),
      'notes': notes,
    };
  }

  factory PerformedExercise.fromJson(Map<String, dynamic> json) {
    return PerformedExercise(
      exerciseId: json['exerciseId'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
    );
  }
}
