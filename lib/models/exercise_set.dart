enum SetType { normal, warmup, dropSet, failure }

class ExerciseSet {
  final String id;
  double weight; // Poids en kg (ou niveau de résistance / lest)
  int reps; // Répétitions effectuées
  bool isCompleted; // Validée par la case à cocher
  SetType type;
  int duration; // Durée en secondes
  double distance; // Distance en kilomètres
  String tempo; // Code tempo ex: "3010"
  int workTime; // Temps d'effort en secondes (pour les séries fractionnées)
  int intervalRest; // Temps de repos inter-intervalle en secondes
  
  // Attributs calculés localement pour les records
  bool isWeightPR;
  bool is1RMPR;

  ExerciseSet({
    required this.id,
    this.weight = 0.0,
    this.reps = 0,
    this.isCompleted = false,
    this.type = SetType.normal,
    this.isWeightPR = false,
    this.is1RMPR = false,
    this.duration = 0,
    this.distance = 0.0,
    this.tempo = '2010',
    this.workTime = 0,
    this.intervalRest = 0,
  });

  // Calcul du One Rep Max estimé (Formule d'Epley)
  double get estimated1RM {
    if (reps <= 1) return weight;
    return weight * (1 + reps / 30.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weight': weight,
      'reps': reps,
      'isCompleted': isCompleted,
      'type': type.name,
      'isWeightPR': isWeightPR,
      'is1RMPR': is1RMPR,
      'duration': duration,
      'distance': distance,
      'tempo': tempo,
      'workTime': workTime,
      'intervalRest': intervalRest,
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      id: json['id'] as String,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      reps: json['reps'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      type: SetType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SetType.normal,
      ),
      isWeightPR: json['isWeightPR'] as bool? ?? false,
      is1RMPR: json['is1RMPR'] as bool? ?? false,
      duration: json['duration'] as int? ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      tempo: json['tempo'] as String? ?? '2010',
      workTime: json['workTime'] as int? ?? 0,
      intervalRest: json['intervalRest'] as int? ?? 0,
    );
  }
}

