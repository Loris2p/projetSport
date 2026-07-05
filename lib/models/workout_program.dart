import 'exercise.dart';

class WorkoutProgram {
  final String id;
  final String name;
  final String description;
  final List<Exercise> exercises;
  final Map<String, String>? exerciseGroups;

  WorkoutProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.exercises,
    this.exerciseGroups,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'exerciseGroups': exerciseGroups,
    };
  }

  factory WorkoutProgram.fromJson(Map<String, dynamic> json) {
    return WorkoutProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      exerciseGroups: json['exerciseGroups'] != null
          ? Map<String, String>.from(json['exerciseGroups'] as Map)
          : null,
    );
  }
}
