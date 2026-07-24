class PersonalRecord {
  final String exerciseId;
  final double maxWeight;
  final double max1RM;
  final DateTime? maxWeightDate;
  final DateTime? max1RMDate;
  final DateTime updatedAt;

  PersonalRecord({
    required this.exerciseId,
    this.maxWeight = 0.0,
    this.max1RM = 0.0,
    this.maxWeightDate,
    this.max1RMDate,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'exerciseId': exerciseId,
      'maxWeight': maxWeight,
      'max1RM': max1RM,
      'maxWeightDate': maxWeightDate?.toIso8601String(),
      'max1RMDate': max1RMDate?.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PersonalRecord.fromJson(Map<String, dynamic> json) {
    return PersonalRecord(
      exerciseId: json['exerciseId'] as String,
      maxWeight: (json['maxWeight'] as num?)?.toDouble() ?? 0.0,
      max1RM: (json['max1RM'] as num?)?.toDouble() ?? 0.0,
      maxWeightDate: json['maxWeightDate'] != null
          ? DateTime.tryParse(json['maxWeightDate'] as String)
          : null,
      max1RMDate: json['max1RMDate'] != null
          ? DateTime.tryParse(json['max1RMDate'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  PersonalRecord copyWith({
    String? exerciseId,
    double? maxWeight,
    double? max1RM,
    DateTime? maxWeightDate,
    DateTime? max1RMDate,
    DateTime? updatedAt,
  }) {
    return PersonalRecord(
      exerciseId: exerciseId ?? this.exerciseId,
      maxWeight: maxWeight ?? this.maxWeight,
      max1RM: max1RM ?? this.max1RM,
      maxWeightDate: maxWeightDate ?? this.maxWeightDate,
      max1RMDate: max1RMDate ?? this.max1RMDate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
