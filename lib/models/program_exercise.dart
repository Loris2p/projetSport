class ProgramExercise {
  final String exerciseId;
  final int setsCount;
  final int repsCount;
  final int restTime; // Temps de repos en secondes

  ProgramExercise({
    required this.exerciseId,
    required this.setsCount,
    required this.repsCount,
    required this.restTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'setsCount': setsCount,
      'repsCount': repsCount,
      'restTime': restTime,
    };
  }

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      exerciseId: json['exerciseId'] as String,
      setsCount: json['setsCount'] as int,
      repsCount: json['repsCount'] as int,
      restTime: json['restTime'] as int,
    );
  }
}
