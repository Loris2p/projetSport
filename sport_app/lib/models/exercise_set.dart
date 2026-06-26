enum SetType { normal, warmup, dropSet, failure }

class ExerciseSet {
  final String id;
  double weight; // Poids en kg
  int reps; // Répétitions effectuées
  bool isCompleted; // Validée par la case à cocher
  SetType type;
  
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
    };
  }

  factory ExerciseSet.fromJson(Map<String, dynamic> json) {
    return ExerciseSet(
      id: json['id'] as String,
      weight: (json['weight'] as num).toDouble(),
      reps: json['reps'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      type: SetType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SetType.normal,
      ),
      isWeightPR: json['isWeightPR'] as bool? ?? false,
      is1RMPR: json['is1RMPR'] as bool? ?? false,
    );
  }
}
