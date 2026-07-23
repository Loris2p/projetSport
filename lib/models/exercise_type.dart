import 'package:flutter/material.dart';

enum ExerciseType {
  reps(
    'reps',
    'Répétitions & Charge',
    'Musculation classique avec nombre de répétitions et poids.',
    ['SÉRIE', 'POIDS (KG)', 'RÉPETS', 'OK'],
    Icons.fitness_center,
  ),
  isometry(
    'isometry',
    'Isométrie & Gainage',
    'Maintien d\'une position statique sous tension pendant une durée cible.',
    ['SÉRIE', 'LEST (KG)', 'DURÉE', 'OK'],
    Icons.timer,
  ),
  cardio(
    'cardio',
    'Cardio Continu',
    'Effort continu en course, vélo, rameur (distance, temps, allure).',
    ['SÉRIE', 'DISTANCE (KM)', 'DURÉE', 'ALLURE', 'OK'],
    Icons.directions_run,
  ),
  intervals(
    'intervals',
    'Fractionné / HIIT',
    'Alternance de temps d\'effort intense et de récupération.',
    ['TOUR', 'EFFORT', 'REPOS', 'REPS/DIST', 'OK'],
    Icons.speed,
  ),
  amrap(
    'amrap',
    'AMRAP (Reps max)',
    'Réaliser le maximum de répétitions/tours dans un temps chrono fixe.',
    ['SÉRIE', 'CHRONO', 'REPS TOTAL', 'OK'],
    Icons.bolt,
  ),
  emom(
    'emom',
    'EMOM (Chaque minute)',
    'Tâche de répétitions à accomplir au début de chaque minute.',
    ['MINUTE', 'CIBLE', 'RÉALISÉ', 'OK'],
    Icons.av_timer,
  ),
  forTime(
    'forTime',
    'For Time (Chrono)',
    'Effectuer un nombre de répétitions fixé le plus rapidement possible.',
    ['SÉRIE', 'REPS CIBLE', 'TEMPS CHRONO', 'OK'],
    Icons.alarm_on,
  ),
  video(
    'video',
    'Cours Vidéo / Média',
    'Séance ou cours guidé vidéo/audio associé à une durée.',
    ['SÉRIE', 'DURÉE (MIN)', 'VIDÉO', 'OK'],
    Icons.video_library,
  ),
  tempo(
    'tempo',
    'Tempo Training',
    'Répétitions avec cadence excentrique/concentrique contrôlée (ex: 3010).',
    ['SÉRIE', 'POIDS (KG)', 'TEMPO', 'RÉPETS', 'OK'],
    Icons.access_time,

  ),
  circuit(
    'circuit',
    'Superset / Circuit',
    'Enchaînement direct de plusieurs exercices sans repos.',
    ['SÉRIE', 'EXERCICE', 'REPS/TEMPS', 'OK'],
    Icons.autorenew,
  );

  final String name;
  final String label;
  final String description;
  final List<String> headers;
  final IconData icon;

  const ExerciseType(
    this.name,
    this.label,
    this.description,
    this.headers,
    this.icon,
  );

  static ExerciseType fromString(String? value) {
    if (value == null) return ExerciseType.reps;
    // Compatibilité éventuelle avec d'anciens termes 'time' et 'distance'
    if (value == 'time') return ExerciseType.isometry;
    if (value == 'distance') return ExerciseType.cardio;

    return ExerciseType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ExerciseType.reps,
    );
  }
}

