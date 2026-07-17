enum ExerciseType {
  reps(
    'reps',
    'Répétitions & Poids',
    ['SÉRIE', 'POIDS (KG)', 'RÉPETS', 'OK'],
  ),
  time(
    'time',
    'Temps / Durée',
    ['SÉRIE', 'RÉSISTANCE', 'TEMPS', 'OK'],
  ),
  distance(
    'distance',
    'Distance & Temps',
    ['SÉRIE', 'DISTANCE (KM)', 'TEMPS', 'OK'],
  );

  final String name;
  final String label;
  final List<String> headers;

  const ExerciseType(this.name, this.label, this.headers);

  static ExerciseType fromString(String? value) {
    return ExerciseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseType.reps,
    );
  }
}
