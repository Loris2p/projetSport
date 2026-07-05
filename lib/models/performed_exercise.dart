import 'exercise_set.dart';

class PerformedExercise {
  final String exerciseId;
  final List<ExerciseSet> sets;
  String? notes; 
  String? groupId;

  PerformedExercise({
    required this.exerciseId,
    required this.sets,
    this.notes,
    this.groupId,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'sets': sets.map((s) => s.toJson()).toList(),
      'notes': notes,
      'groupId': groupId,
    };
  }

  factory PerformedExercise.fromJson(Map<String, dynamic> json) {
    return PerformedExercise(
      exerciseId: json['exerciseId'] as String,
      sets: (json['sets'] as List<dynamic>)
          .map((s) => ExerciseSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      notes: json['notes'] as String?,
      groupId: json['groupId'] as String?,
    );
  }
}
