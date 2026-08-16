class BodyMeasurement {
  final String id;
  final DateTime date;
  final double? weight; // in kg
  final double? height; // in cm
  final double? bodyFatPercentage; // in %
  final double? waterPercentage; // in %
  final double? musclePercentage; // in %
  final double? boneMass; // in kg
  final String? note;

  BodyMeasurement({
    required this.id,
    required this.date,
    this.weight,
    this.height,
    this.bodyFatPercentage,
    this.waterPercentage,
    this.musclePercentage,
    this.boneMass,
    this.note,
  });

  /// Indice de Masse Corporelle (IMC / BMI)
  double? get bmi {
    if (weight == null || height == null || height! <= 0) return null;
    final heightInMeters = height! / 100.0;
    return weight! / (heightInMeters * heightInMeters);
  }

  /// Catégorie IMC selon l'OMS
  String? get bmiCategory {
    final value = bmi;
    if (value == null) return null;
    if (value < 18.5) return 'Insuffisance pondérale';
    if (value < 25.0) return 'Corpulence normale';
    if (value < 30.0) return 'Surpoids';
    if (value < 35.0) return 'Obésité modérée';
    return 'Obésité sévère';
  }

  /// Masse grasse calculée en kg
  double? get fatMassKg {
    if (weight == null || bodyFatPercentage == null) return null;
    return weight! * (bodyFatPercentage! / 100.0);
  }

  /// Masse musculaire calculée en kg
  double? get muscleMassKg {
    if (weight == null || musclePercentage == null) return null;
    return weight! * (musclePercentage! / 100.0);
  }

  /// Masse hydrique calculée en kg / Litres
  double? get waterMassKg {
    if (weight == null || waterPercentage == null) return null;
    return weight! * (waterPercentage! / 100.0);
  }

  BodyMeasurement copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? height,
    double? bodyFatPercentage,
    double? waterPercentage,
    double? musclePercentage,
    double? boneMass,
    String? note,
  }) {
    return BodyMeasurement(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      height: height ?? this.height,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      waterPercentage: waterPercentage ?? this.waterPercentage,
      musclePercentage: musclePercentage ?? this.musclePercentage,
      boneMass: boneMass ?? this.boneMass,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weight': weight,
      'height': height,
      'bodyFatPercentage': bodyFatPercentage,
      'waterPercentage': waterPercentage,
      'musclePercentage': musclePercentage,
      'boneMass': boneMass,
      'note': note,
    };
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['date'] != null) {
      if (json['date'] is String) {
        parsedDate = DateTime.tryParse(json['date'] as String) ?? DateTime.now();
      } else {
        try {
          parsedDate = (json['date'] as dynamic).toDate();
        } catch (_) {
          parsedDate = DateTime.tryParse(json['date'].toString()) ?? DateTime.now();
        }
      }
    } else {
      parsedDate = DateTime.now();
    }

    return BodyMeasurement(
      id: json['id'] as String? ?? '',
      date: parsedDate,
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bodyFatPercentage: (json['bodyFatPercentage'] as num?)?.toDouble(),
      waterPercentage: (json['waterPercentage'] as num?)?.toDouble(),
      musclePercentage: (json['musclePercentage'] as num?)?.toDouble(),
      boneMass: (json['boneMass'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }
}
