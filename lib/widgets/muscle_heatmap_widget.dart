import 'package:flutter/material.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../theme.dart';
import 'category_badge.dart';

enum HeatmapTimeRange {
  sevenDays,
  thirtyDays,
  thisYear,
  allTime,
}

class MuscleHeatmapWidget extends StatefulWidget {
  final WorkoutProvider provider;

  const MuscleHeatmapWidget({super.key, required this.provider});

  @override
  State<MuscleHeatmapWidget> createState() => _MuscleHeatmapWidgetState();
}

class _MuscleHeatmapWidgetState extends State<MuscleHeatmapWidget> {
  HeatmapTimeRange _selectedRange = HeatmapTimeRange.sevenDays;
  bool _isFrontView = true; // true = Face, false = Dos
  String? _selectedMuscle;

  @override
  Widget build(BuildContext context) {
    final history = widget.provider.history;
    final now = DateTime.now();

    // 1. Filtrer les séances selon la plage temporelle choisie
    final filteredSessions = history.where((s) {
      switch (_selectedRange) {
        case HeatmapTimeRange.sevenDays:
          return s.startTime.isAfter(now.subtract(const Duration(days: 7)));
        case HeatmapTimeRange.thirtyDays:
          return s.startTime.isAfter(now.subtract(const Duration(days: 30)));
        case HeatmapTimeRange.thisYear:
          return s.startTime.year == now.year;
        case HeatmapTimeRange.allTime:
          return true;
      }
    }).toList();

    // 2. Agréger les séries complétées et le volume par groupe musculaire
    final Map<String, int> setsPerMuscle = {
      'Pectoraux': 0,
      'Dos': 0,
      'Épaules': 0,
      'Biceps': 0,
      'Triceps': 0,
      'Abdominaux': 0,
      'Fessiers': 0,
      'Jambes': 0,
      'Mollets': 0,
    };

    final Map<String, double> volumePerMuscle = {
      'Pectoraux': 0.0,
      'Dos': 0.0,
      'Épaules': 0.0,
      'Biceps': 0.0,
      'Triceps': 0.0,
      'Abdominaux': 0.0,
      'Fessiers': 0.0,
      'Jambes': 0.0,
      'Mollets': 0.0,
    };

    final Map<String, Set<String>> exercisesPerMuscle = {
      'Pectoraux': {},
      'Dos': {},
      'Épaules': {},
      'Biceps': {},
      'Triceps': {},
      'Abdominaux': {},
      'Fessiers': {},
      'Jambes': {},
      'Mollets': {},
    };

    for (var session in filteredSessions) {
      for (var perfEx in session.exercises) {
        final exercise = widget.provider.exercises.firstWhere(
          (e) => e.id == perfEx.exerciseId,
          orElse: () => Exercise(id: perfEx.exerciseId, name: 'Inconnu', category: 'Autre'),
        );

        final completedSets = perfEx.sets.where((s) => s.isCompleted).toList();
        if (completedSets.isEmpty) continue;

        // Distribuer les catégories de l'exercice
        final cats = exercise.categories.isNotEmpty ? exercise.categories : [exercise.category];
        for (var cat in cats) {
          String targetMuscle = cat;
          if (cat == 'Bras') targetMuscle = 'Biceps'; // fallback

          if (setsPerMuscle.containsKey(targetMuscle)) {
            setsPerMuscle[targetMuscle] = setsPerMuscle[targetMuscle]! + completedSets.length;
            double vol = completedSets.fold(0.0, (sum, s) => sum + (s.weight * s.reps));
            volumePerMuscle[targetMuscle] = volumePerMuscle[targetMuscle]! + vol;
            exercisesPerMuscle[targetMuscle]!.add(exercise.name);
          } else if (cat == 'Jambes') {
            setsPerMuscle['Jambes'] = setsPerMuscle['Jambes']! + completedSets.length;
            setsPerMuscle['Mollets'] = setsPerMuscle['Mollets']! + (completedSets.length ~/ 2);
            double vol = completedSets.fold(0.0, (sum, s) => sum + (s.weight * s.reps));
            volumePerMuscle['Jambes'] = volumePerMuscle['Jambes']! + vol;
            exercisesPerMuscle['Jambes']!.add(exercise.name);
          }
        }
      }
    }

    final maxSets = setsPerMuscle.values.fold(0, (max, v) => v > max ? v : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Time range selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.accessibility_rounded, color: AppTheme.athleticBlue, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Carte thermique musculaire",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Intensité et volume par groupe",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              // Dropdown time range
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.darkBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<HeatmapTimeRange>(
                    value: _selectedRange,
                    dropdownColor: AppTheme.darkSurface,
                    isDense: true,
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: HeatmapTimeRange.sevenDays, child: Text("7 jours")),
                      DropdownMenuItem(value: HeatmapTimeRange.thirtyDays, child: Text("30 jours")),
                      DropdownMenuItem(value: HeatmapTimeRange.thisYear, child: Text("Cette année")),
                      DropdownMenuItem(value: HeatmapTimeRange.allTime, child: Text("Tout")),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedRange = val);
                    },
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Face / Dos View Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: AppTheme.athleticBlue,
                color: Colors.grey,
                constraints: const BoxConstraints(minHeight: 34, minWidth: 120),
                isSelected: [_isFrontView, !_isFrontView],
                onPressed: (idx) {
                  setState(() {
                    _isFrontView = idx == 0;
                  });
                },
                children: const [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16),
                      SizedBox(width: 6),
                      Text("Vue Face", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 16),
                      SizedBox(width: 6),
                      Text("Vue Dos", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Silhouette Vectorielle Interactive
          Center(
            child: SizedBox(
              width: 220,
              height: 310,
              child: CustomPaint(
                painter: HumanBodyHeatmapPainter(
                  isFront: _isFrontView,
                  setsPerMuscle: setsPerMuscle,
                  maxSets: maxSets > 0 ? maxSets : 1,
                  selectedMuscle: _selectedMuscle,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Légende d'intensité
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Repos", style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              const SizedBox(width: 6),
              Container(
                width: 120,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xff334155), // Slate 700 (Repos)
                      Color(0xff38bdf8), // Sky Blue (Faible)
                      Color(0xff10b981), // Emerald (Moyen)
                      Color(0xfff59e0b), // Amber (Élevé)
                      Color(0xffef4444), // Red (Intense)
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text("Intense", style: TextStyle(color: Colors.red[400], fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),

          // Cartouche de détail du muscle sélectionné ou grille des muscles
          if (_selectedMuscle != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.athleticBlue.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CategoryBadge(category: _selectedMuscle!, compact: true),
                          const SizedBox(width: 8),
                          Text(
                            _selectedMuscle!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                        onPressed: () => setState(() => _selectedMuscle = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Séries validées : ${setsPerMuscle[_selectedMuscle] ?? 0}",
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Volume : ${(volumePerMuscle[_selectedMuscle] ?? 0).toStringAsFixed(0)} kg",
                          style: const TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                  if ((exercisesPerMuscle[_selectedMuscle] ?? {}).isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      "Exercices : ${(exercisesPerMuscle[_selectedMuscle]!).join(', ')}",
                      style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Liste horizontale de sélection rapide des muscles
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: setsPerMuscle.keys.map((muscle) {
              final sets = setsPerMuscle[muscle] ?? 0;
              final isSelected = _selectedMuscle == muscle;

              return ChoiceChip(
                label: Text(
                  "$muscle ($sets)",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : (sets > 0 ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppTheme.athleticBlue,
                backgroundColor: AppTheme.darkBg,
                onSelected: (sel) {
                  setState(() {
                    _selectedMuscle = sel ? muscle : null;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ==================== PAINTER ANATOMIQUE VECTORIEL ====================

class HumanBodyHeatmapPainter extends CustomPainter {
  final bool isFront;
  final Map<String, int> setsPerMuscle;
  final int maxSets;
  final String? selectedMuscle;

  HumanBodyHeatmapPainter({
    required this.isFront,
    required this.setsPerMuscle,
    required this.maxSets,
    this.selectedMuscle,
  });

  Color _getMuscleColor(String muscle) {
    final count = setsPerMuscle[muscle] ?? 0;
    if (count == 0) return const Color(0xff334155).withValues(alpha: 0.5); // Gris neutre non sollicité

    final ratio = (count / maxSets).clamp(0.1, 1.0);
    if (ratio < 0.25) return const Color(0xff38bdf8); // Sky blue
    if (ratio < 0.5) return const Color(0xff10b981); // Emerald
    if (ratio < 0.75) return const Color(0xfff59e0b); // Amber
    return const Color(0xffef4444); // Red
  }

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bodyPaint = Paint()..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xff475569);

    final highlightStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.white;

    // 1. TÊTE & COU
    final headCenter = Offset(centerX, 25);
    bodyPaint.color = const Color(0xff1e293b);
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: 34, height: 42), bodyPaint);
    canvas.drawOval(Rect.fromCenter(center: headCenter, width: 34, height: 42), strokePaint);

    // Cou
    final neckPath = Path()
      ..moveTo(centerX - 10, 42)
      ..lineTo(centerX + 10, 42)
      ..lineTo(centerX + 12, 54)
      ..lineTo(centerX - 12, 54)
      ..close();
    canvas.drawPath(neckPath, bodyPaint);

    if (isFront) {
      // ==================== VUE FACE ====================

      // Épaules (Deltoïdes)
      final leftDeltoid = Path()
        ..moveTo(centerX - 36, 56)
        ..quadraticBezierTo(centerX - 56, 62, centerX - 56, 80)
        ..quadraticBezierTo(centerX - 42, 86, centerX - 36, 78)
        ..close();
      final rightDeltoid = Path()
        ..moveTo(centerX + 36, 56)
        ..quadraticBezierTo(centerX + 56, 62, centerX + 56, 80)
        ..quadraticBezierTo(centerX + 42, 86, centerX + 36, 78)
        ..close();

      bodyPaint.color = _getMuscleColor('Épaules');
      canvas.drawPath(leftDeltoid, bodyPaint);
      canvas.drawPath(rightDeltoid, bodyPaint);
      canvas.drawPath(leftDeltoid, selectedMuscle == 'Épaules' ? highlightStroke : strokePaint);
      canvas.drawPath(rightDeltoid, selectedMuscle == 'Épaules' ? highlightStroke : strokePaint);

      // Pectoraux
      final leftPec = Path()
        ..moveTo(centerX - 3, 60)
        ..lineTo(centerX - 34, 60)
        ..quadraticBezierTo(centerX - 38, 86, centerX - 4, 90)
        ..close();
      final rightPec = Path()
        ..moveTo(centerX + 3, 60)
        ..lineTo(centerX + 34, 60)
        ..quadraticBezierTo(centerX + 38, 86, centerX + 4, 90)
        ..close();

      bodyPaint.color = _getMuscleColor('Pectoraux');
      canvas.drawPath(leftPec, bodyPaint);
      canvas.drawPath(rightPec, bodyPaint);
      canvas.drawPath(leftPec, selectedMuscle == 'Pectoraux' ? highlightStroke : strokePaint);
      canvas.drawPath(rightPec, selectedMuscle == 'Pectoraux' ? highlightStroke : strokePaint);

      // Abdominaux
      final absPath = Path()
        ..moveTo(centerX - 18, 94)
        ..lineTo(centerX + 18, 94)
        ..quadraticBezierTo(centerX + 14, 134, centerX + 18, 148)
        ..lineTo(centerX - 18, 148)
        ..quadraticBezierTo(centerX - 14, 134, centerX - 18, 94)
        ..close();

      bodyPaint.color = _getMuscleColor('Abdominaux');
      canvas.drawPath(absPath, bodyPaint);
      canvas.drawPath(absPath, selectedMuscle == 'Abdominaux' ? highlightStroke : strokePaint);

      // Biceps & Bras
      final leftBiceps = Path()
        ..moveTo(centerX - 46, 84)
        ..quadraticBezierTo(centerX - 58, 105, centerX - 48, 126)
        ..lineTo(centerX - 38, 122)
        ..quadraticBezierTo(centerX - 40, 100, centerX - 38, 84)
        ..close();
      final rightBiceps = Path()
        ..moveTo(centerX + 46, 84)
        ..quadraticBezierTo(centerX + 58, 105, centerX + 48, 126)
        ..lineTo(centerX + 38, 122)
        ..quadraticBezierTo(centerX + 40, 100, centerX + 38, 84)
        ..close();

      bodyPaint.color = _getMuscleColor('Biceps');
      canvas.drawPath(leftBiceps, bodyPaint);
      canvas.drawPath(rightBiceps, bodyPaint);
      canvas.drawPath(leftBiceps, selectedMuscle == 'Biceps' ? highlightStroke : strokePaint);
      canvas.drawPath(rightBiceps, selectedMuscle == 'Biceps' ? highlightStroke : strokePaint);

      // Avant-bras
      final leftForearm = Path()
        ..moveTo(centerX - 48, 130)
        ..quadraticBezierTo(centerX - 62, 155, centerX - 54, 180)
        ..lineTo(centerX - 44, 176)
        ..quadraticBezierTo(centerX - 40, 150, centerX - 40, 128)
        ..close();
      final rightForearm = Path()
        ..moveTo(centerX + 48, 130)
        ..quadraticBezierTo(centerX + 62, 155, centerX + 54, 180)
        ..lineTo(centerX + 44, 176)
        ..quadraticBezierTo(centerX + 40, 150, centerX + 40, 128)
        ..close();

      bodyPaint.color = const Color(0xff334155).withValues(alpha: 0.7);
      canvas.drawPath(leftForearm, bodyPaint);
      canvas.drawPath(rightForearm, bodyPaint);
      canvas.drawPath(leftForearm, strokePaint);
      canvas.drawPath(rightForearm, strokePaint);

      // Quadriceps (Cuisses face)
      final leftQuad = Path()
        ..moveTo(centerX - 4, 154)
        ..lineTo(centerX - 24, 154)
        ..quadraticBezierTo(centerX - 32, 195, centerX - 24, 228)
        ..lineTo(centerX - 6, 228)
        ..quadraticBezierTo(centerX - 4, 190, centerX - 4, 154)
        ..close();
      final rightQuad = Path()
        ..moveTo(centerX + 4, 154)
        ..lineTo(centerX + 24, 154)
        ..quadraticBezierTo(centerX + 32, 195, centerX + 24, 228)
        ..lineTo(centerX + 6, 228)
        ..quadraticBezierTo(centerX + 4, 190, centerX + 4, 154)
        ..close();

      bodyPaint.color = _getMuscleColor('Jambes');
      canvas.drawPath(leftQuad, bodyPaint);
      canvas.drawPath(rightQuad, bodyPaint);
      canvas.drawPath(leftQuad, selectedMuscle == 'Jambes' ? highlightStroke : strokePaint);
      canvas.drawPath(rightQuad, selectedMuscle == 'Jambes' ? highlightStroke : strokePaint);

      // Mollets Face
      final leftCalf = Path()
        ..moveTo(centerX - 7, 234)
        ..lineTo(centerX - 23, 234)
        ..quadraticBezierTo(centerX - 26, 265, centerX - 18, 290)
        ..lineTo(centerX - 10, 290)
        ..quadraticBezierTo(centerX - 8, 265, centerX - 7, 234)
        ..close();
      final rightCalf = Path()
        ..moveTo(centerX + 7, 234)
        ..lineTo(centerX + 23, 234)
        ..quadraticBezierTo(centerX + 26, 265, centerX + 18, 290)
        ..lineTo(centerX + 10, 290)
        ..quadraticBezierTo(centerX + 8, 265, centerX + 7, 234)
        ..close();

      bodyPaint.color = _getMuscleColor('Mollets');
      canvas.drawPath(leftCalf, bodyPaint);
      canvas.drawPath(rightCalf, bodyPaint);
      canvas.drawPath(leftCalf, selectedMuscle == 'Mollets' ? highlightStroke : strokePaint);
      canvas.drawPath(rightCalf, selectedMuscle == 'Mollets' ? highlightStroke : strokePaint);
    } else {
      // ==================== VUE DOS ====================

      // Trapèzes & Haut du dos
      final trapsPath = Path()
        ..moveTo(centerX - 12, 54)
        ..lineTo(centerX + 12, 54)
        ..lineTo(centerX + 34, 60)
        ..quadraticBezierTo(centerX, 95, centerX - 34, 60)
        ..close();

      bodyPaint.color = _getMuscleColor('Dos');
      canvas.drawPath(trapsPath, bodyPaint);
      canvas.drawPath(trapsPath, selectedMuscle == 'Dos' ? highlightStroke : strokePaint);

      // Grands Dorsaux
      final latsPath = Path()
        ..moveTo(centerX - 32, 65)
        ..quadraticBezierTo(centerX - 42, 95, centerX - 16, 130)
        ..lineTo(centerX + 16, 130)
        ..quadraticBezierTo(centerX + 42, 95, centerX + 32, 65)
        ..quadraticBezierTo(centerX, 95, centerX - 32, 65)
        ..close();

      canvas.drawPath(latsPath, bodyPaint);
      canvas.drawPath(latsPath, selectedMuscle == 'Dos' ? highlightStroke : strokePaint);

      // Triceps
      final leftTriceps = Path()
        ..moveTo(centerX - 46, 80)
        ..quadraticBezierTo(centerX - 58, 102, centerX - 48, 124)
        ..lineTo(centerX - 38, 120)
        ..quadraticBezierTo(centerX - 38, 98, centerX - 38, 80)
        ..close();
      final rightTriceps = Path()
        ..moveTo(centerX + 46, 80)
        ..quadraticBezierTo(centerX + 58, 102, centerX + 48, 124)
        ..lineTo(centerX + 38, 120)
        ..quadraticBezierTo(centerX + 38, 98, centerX + 38, 80)
        ..close();

      bodyPaint.color = _getMuscleColor('Triceps');
      canvas.drawPath(leftTriceps, bodyPaint);
      canvas.drawPath(rightTriceps, bodyPaint);
      canvas.drawPath(leftTriceps, selectedMuscle == 'Triceps' ? highlightStroke : strokePaint);
      canvas.drawPath(rightTriceps, selectedMuscle == 'Triceps' ? highlightStroke : strokePaint);

      // Fessiers
      final glutesPath = Path()
        ..moveTo(centerX - 24, 136)
        ..lineTo(centerX + 24, 136)
        ..quadraticBezierTo(centerX + 30, 168, centerX + 3, 172)
        ..lineTo(centerX, 172)
        ..lineTo(centerX - 3, 172)
        ..quadraticBezierTo(centerX - 30, 168, centerX - 24, 136)
        ..close();

      bodyPaint.color = _getMuscleColor('Fessiers');
      canvas.drawPath(glutesPath, bodyPaint);
      canvas.drawPath(glutesPath, selectedMuscle == 'Fessiers' ? highlightStroke : strokePaint);

      // Ischio-jambiers (Arrière des cuisses)
      final leftHamstring = Path()
        ..moveTo(centerX - 4, 174)
        ..lineTo(centerX - 26, 174)
        ..quadraticBezierTo(centerX - 30, 205, centerX - 23, 230)
        ..lineTo(centerX - 6, 230)
        ..quadraticBezierTo(centerX - 4, 200, centerX - 4, 174)
        ..close();
      final rightHamstring = Path()
        ..moveTo(centerX + 4, 174)
        ..lineTo(centerX + 26, 174)
        ..quadraticBezierTo(centerX + 30, 205, centerX + 23, 230)
        ..lineTo(centerX + 6, 230)
        ..quadraticBezierTo(centerX + 4, 200, centerX + 4, 174)
        ..close();

      bodyPaint.color = _getMuscleColor('Jambes');
      canvas.drawPath(leftHamstring, bodyPaint);
      canvas.drawPath(rightHamstring, bodyPaint);
      canvas.drawPath(leftHamstring, selectedMuscle == 'Jambes' ? highlightStroke : strokePaint);
      canvas.drawPath(rightHamstring, selectedMuscle == 'Jambes' ? highlightStroke : strokePaint);

      // Mollets Dos
      final leftCalfBack = Path()
        ..moveTo(centerX - 7, 234)
        ..lineTo(centerX - 24, 234)
        ..quadraticBezierTo(centerX - 28, 265, centerX - 18, 290)
        ..lineTo(centerX - 10, 290)
        ..quadraticBezierTo(centerX - 8, 265, centerX - 7, 234)
        ..close();
      final rightCalfBack = Path()
        ..moveTo(centerX + 7, 234)
        ..lineTo(centerX + 24, 234)
        ..quadraticBezierTo(centerX + 28, 265, centerX + 18, 290)
        ..lineTo(centerX + 10, 290)
        ..quadraticBezierTo(centerX + 8, 265, centerX + 7, 234)
        ..close();

      bodyPaint.color = _getMuscleColor('Mollets');
      canvas.drawPath(leftCalfBack, bodyPaint);
      canvas.drawPath(rightCalfBack, bodyPaint);
      canvas.drawPath(leftCalfBack, selectedMuscle == 'Mollets' ? highlightStroke : strokePaint);
      canvas.drawPath(rightCalfBack, selectedMuscle == 'Mollets' ? highlightStroke : strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HumanBodyHeatmapPainter oldDelegate) {
    return oldDelegate.isFront != isFront ||
        oldDelegate.setsPerMuscle != setsPerMuscle ||
        oldDelegate.selectedMuscle != selectedMuscle ||
        oldDelegate.maxSets != maxSets;
  }
}
