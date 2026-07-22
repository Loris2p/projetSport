import 'performed_exercise.dart';

class WorkoutSession {
  final String id;
  final String? programId;
  final String name;
  final DateTime startTime;
  final DateTime? endTime;
  final List<PerformedExercise> exercises;
  
  // Données de santé
  double? activeCaloriesBurned;
  double? averageHeartRate;

  // Ressenti & Notes
  int? rating;
  String? notes;

  WorkoutSession({
    required this.id,
    this.programId,
    required this.name,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.activeCaloriesBurned,
    this.averageHeartRate,
    this.rating,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'programId': programId,
      'name': name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'activeCaloriesBurned': activeCaloriesBurned,
      'averageHeartRate': averageHeartRate,
      'rating': rating,
      'notes': notes,
    };
  }

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String,
      programId: json['programId'] as String?,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => PerformedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeCaloriesBurned: (json['activeCaloriesBurned'] as num?)?.toDouble(),
      averageHeartRate: (json['averageHeartRate'] as num?)?.toDouble(),
      rating: json['rating'] as int?,
      notes: json['notes'] as String?,
    );
  }
}
