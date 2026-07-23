import 'exercise_type.dart';

class ProgramExercise {
  final String exerciseId;
  final ExerciseType type;
  final int setsCount;
  final int repsCount;
  final int restTime; // Temps de repos principal en secondes
  final int durationTarget; // Temps cible en secondes (isométrie, cours vidéo, cardio)
  final double distanceTarget; // Distance cible en km (cardio)
  final int workTime; // Temps d'effort en secondes (fractionné)
  final int intervalRestTime; // Temps de repos inter-intervalle en secondes (fractionné)
  final String tempoCode; // Code tempo ex: "3010"
  final String? videoUrl; // Lien vidéo spécifique pour cours vidéo
  final String? groupId; // ID de groupe pour superset/circuit

  ProgramExercise({
    required this.exerciseId,
    this.type = ExerciseType.reps,
    required this.setsCount,
    required this.repsCount,
    required this.restTime,
    this.durationTarget = 0,
    this.distanceTarget = 0.0,
    this.workTime = 0,
    this.intervalRestTime = 0,
    this.tempoCode = '2010',
    this.videoUrl,
    this.groupId,
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
      'workTime': workTime,
      'intervalRestTime': intervalRestTime,
      'tempoCode': tempoCode,
      'videoUrl': videoUrl,
      'groupId': groupId,
    };
  }

  factory ProgramExercise.fromJson(Map<String, dynamic> json) {
    return ProgramExercise(
      exerciseId: json['exerciseId'] as String,
      type: ExerciseType.fromString(json['type'] as String?),
      setsCount: json['setsCount'] as int? ?? 1,
      repsCount: json['repsCount'] as int? ?? 0,
      restTime: json['restTime'] as int? ?? 60,
      durationTarget: json['durationTarget'] as int? ?? 0,
      distanceTarget: (json['distanceTarget'] as num?)?.toDouble() ?? 0.0,
      workTime: json['workTime'] as int? ?? 0,
      intervalRestTime: json['intervalRestTime'] as int? ?? 0,
      tempoCode: json['tempoCode'] as String? ?? '2010',
      videoUrl: json['videoUrl'] as String?,
      groupId: json['groupId'] as String?,
    );
  }
}


