enum ExerciseType { reps, time, distance }

class Exercise {
  final String id;
  final String name;
  final String category; // ex: Pectoraux, Dos, Jambes, Cardio
  final String? notes; 
  final bool isCustom; 
  final ExerciseType type;

  Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.notes,
    this.isCustom = false,
    this.type = ExerciseType.reps,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'notes': notes,
      'isCustom': isCustom,
      'type': type.name,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      notes: json['notes'] as String?,
      isCustom: json['isCustom'] as bool? ?? false,
      type: ExerciseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ExerciseType.reps,
      ),
    );
  }
}
