import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../providers/workout_provider.dart';
import '../theme.dart';

class CorrelationChartWidget extends StatefulWidget {
  final WorkoutProvider provider;

  const CorrelationChartWidget({super.key, required this.provider});

  @override
  State<CorrelationChartWidget> createState() => _CorrelationChartWidgetState();
}

class _CorrelationChartWidgetState extends State<CorrelationChartWidget> {
  String? _selectedExerciseId;
  bool _use1RM = true; // true = 1RM estimé, false = Charge brute max

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final history = provider.history;
    final measurements = provider.bodyMeasurements;

    // Récupérer les exercices qui ont au moins une série validée
    final Set<String> performedExerciseIds = {};
    for (var session in history) {
      for (var ex in session.exercises) {
        if (ex.sets.any((s) => s.isCompleted)) {
          performedExerciseIds.add(ex.exerciseId);
        }
      }
    }

    final availableExercises = provider.exercises
        .where((e) => performedExerciseIds.contains(e.id))
        .toList();

    if (availableExercises.isEmpty || measurements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.darkBorder),
        ),
        child: Column(
          children: [
            Icon(Icons.compare_arrows_rounded, size: 48, color: Colors.grey[600]),
            const SizedBox(height: 12),
            const Text(
              "Données insuffisantes pour la corrélation",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              "Enregistrez des pesées corporelles et terminez des entraînements pour analyser la relation entre votre poids et votre force.",
              style: TextStyle(color: Colors.grey[400], fontSize: 12, height: 1.3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_selectedExerciseId == null || !performedExerciseIds.contains(_selectedExerciseId)) {
      _selectedExerciseId = availableExercises.first.id;
    }

    final selectedExercise = availableExercises.firstWhere((e) => e.id == _selectedExerciseId);

    // 1. Extraire les points de performance pour l'exercice sélectionné
    final List<Map<String, dynamic>> performancePoints = [];
    for (var session in history.reversed) {
      for (var perfEx in session.exercises) {
        if (perfEx.exerciseId == _selectedExerciseId) {
          final completedSets = perfEx.sets.where((s) => s.isCompleted).toList();
          if (completedSets.isNotEmpty) {
            double val = _use1RM
                ? completedSets.map((s) => s.estimated1RM).reduce((a, b) => a > b ? a : b)
                : completedSets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
            performancePoints.add({
              'date': session.startTime,
              'value': val,
            });
          }
        }
      }
    }

    // 2. Extraire les points de poids de corps
    final List<Map<String, dynamic>> weightPoints = [];
    for (var m in measurements.reversed) {
      if (m.weight != null) {
        weightPoints.add({
          'date': m.date,
          'value': m.weight!,
        });
      }
    }

    // 3. Calculer le ratio de force relative actuel (Dernière perf / Dernier poids)
    double? currentRatio;
    String strengthStandard = "Standard";
    Color standardColor = Colors.grey;

    if (performancePoints.isNotEmpty && weightPoints.isNotEmpty) {
      final latestPerf = performancePoints.last['value'] as double;
      final latestWeight = weightPoints.last['value'] as double;
      if (latestWeight > 0) {
        currentRatio = latestPerf / latestWeight;

        // Classification indicative
        final exNameLower = selectedExercise.name.toLowerCase();
        if (exNameLower.contains('couché') || exNameLower.contains('bench') || exNameLower.contains('développé')) {
          if (currentRatio >= 1.75) {
            strengthStandard = "Niveau Élite 🏆";
            standardColor = Colors.amber;
          } else if (currentRatio >= 1.25) {
            strengthStandard = "Niveau Avancé 🔥";
            standardColor = const Color(0xff10b981);
          } else if (currentRatio >= 0.85) {
            strengthStandard = "Niveau Intermédiaire 💪";
            standardColor = AppTheme.athleticBlue;
          } else {
            strengthStandard = "Niveau Débutant 🌱";
            standardColor = Colors.blueGrey;
          }
        } else if (exNameLower.contains('squat')) {
          if (currentRatio >= 2.2) {
            strengthStandard = "Niveau Élite 🏆";
            standardColor = Colors.amber;
          } else if (currentRatio >= 1.6) {
            strengthStandard = "Niveau Avancé 🔥";
            standardColor = const Color(0xff10b981);
          } else if (currentRatio >= 1.1) {
            strengthStandard = "Niveau Intermédiaire 💪";
            standardColor = AppTheme.athleticBlue;
          } else {
            strengthStandard = "Niveau Débutant 🌱";
            standardColor = Colors.blueGrey;
          }
        } else if (exNameLower.contains('terre') || exNameLower.contains('deadlift')) {
          if (currentRatio >= 2.5) {
            strengthStandard = "Niveau Élite 🏆";
            standardColor = Colors.amber;
          } else if (currentRatio >= 1.9) {
            strengthStandard = "Niveau Avancé 🔥";
            standardColor = const Color(0xff10b981);
          } else if (currentRatio >= 1.3) {
            strengthStandard = "Niveau Intermédiaire 💪";
            standardColor = AppTheme.athleticBlue;
          } else {
            strengthStandard = "Niveau Débutant 🌱";
            standardColor = Colors.blueGrey;
          }
        } else {
          strengthStandard = "Ratio : ${currentRatio.toStringAsFixed(2)}x";
          standardColor = AppTheme.athleticBlue;
        }
      }
    }

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
          // En-tête
          const Row(
            children: [
              Icon(Icons.show_chart_rounded, color: AppTheme.athleticBlue, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Corrélation Poids vs Performances",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "Analysez l'impact de votre masse corporelle sur vos charges de travail.",
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
          const Divider(height: 24),

          // Sélecteur d'exercice
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: DropdownButton<String>(
                value: _selectedExerciseId,
                isExpanded: true,
                dropdownColor: AppTheme.darkSurface,
                items: availableExercises.map((ex) {
                  return DropdownMenuItem(
                    value: ex.id,
                    child: Text(
                      ex.name,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id != null) setState(() => _selectedExerciseId = id);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Toggle 1RM vs Charge Max
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xff3b82f6), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text("Force (kg)", style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 14),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Color(0xff10b981), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text("Poids corporel (kg)", style: TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () => setState(() => _use1RM = !_use1RM),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _use1RM ? AppTheme.athleticBlue.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _use1RM ? AppTheme.athleticBlue : Colors.grey[700]!),
                  ),
                  child: Text(
                    _use1RM ? "Mode : 1RM Estimé" : "Mode : Charge brute",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _use1RM ? AppTheme.athleticBlue : Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Graphique Double Axe Y
          SizedBox(
            height: 220,
            child: DualAxisCorrelationChart(
              perfPoints: performancePoints,
              weightPoints: weightPoints,
            ),
          ),
          const SizedBox(height: 16),

          // Ratio de force relative Badge & Explications
          if (currentRatio != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.darkBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: standardColor.withValues(alpha: 0.15),
                    radius: 22,
                    child: Text(
                      "${currentRatio.toStringAsFixed(1)}x",
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: standardColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "Force Relative : ${currentRatio.toStringAsFixed(2)}x PDC",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strengthStandard,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: standardColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== PAINTER DOUBLE AXE Y ====================

class DualAxisCorrelationChart extends StatelessWidget {
  final List<Map<String, dynamic>> perfPoints;
  final List<Map<String, dynamic>> weightPoints;

  const DualAxisCorrelationChart({
    super.key,
    required this.perfPoints,
    required this.weightPoints,
  });

  @override
  Widget build(BuildContext context) {
    if (perfPoints.isEmpty && weightPoints.isEmpty) {
      return const Center(
        child: Text("Données insuffisantes", style: TextStyle(color: Colors.grey, fontSize: 12)),
      );
    }

    return CustomPaint(
      size: Size.infinite,
      painter: DualAxisPainter(
        perfPoints: perfPoints,
        weightPoints: weightPoints,
      ),
    );
  }
}

class DualAxisPainter extends CustomPainter {
  final List<Map<String, dynamic>> perfPoints;
  final List<Map<String, dynamic>> weightPoints;

  DualAxisPainter({
    required this.perfPoints,
    required this.weightPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (perfPoints.isEmpty && weightPoints.isEmpty) return;

    const double paddingLeft = 36.0;
    const double paddingRight = 36.0;
    const double paddingTop = 16.0;
    const double paddingBottom = 24.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Calcul des min/max pour l'axe Force (gauche, bleu)
    final perfValues = perfPoints.map((p) => p['value'] as double).toList();
    final double minPerf = perfValues.isNotEmpty ? perfValues.reduce((a, b) => a < b ? a : b) : 0.0;
    final double maxPerf = perfValues.isNotEmpty ? perfValues.reduce((a, b) => a > b ? a : b) : 100.0;
    final double perfRange = (maxPerf - minPerf) == 0 ? 10.0 : (maxPerf - minPerf);
    final double adjMinPerf = (minPerf - perfRange * 0.1).clamp(0.0, double.infinity);
    final double adjMaxPerf = maxPerf + perfRange * 0.1;
    final double adjRangePerf = adjMaxPerf - adjMinPerf;

    // Calcul des min/max pour l'axe Poids (droite, vert)
    final weightValues = weightPoints.map((p) => p['value'] as double).toList();
    final double minWeight = weightValues.isNotEmpty ? weightValues.reduce((a, b) => a < b ? a : b) : 40.0;
    final double maxWeight = weightValues.isNotEmpty ? weightValues.reduce((a, b) => a > b ? a : b) : 100.0;
    final double weightRange = (maxWeight - minWeight) == 0 ? 5.0 : (maxWeight - minWeight);
    final double adjMinWeight = (minWeight - weightRange * 0.1).clamp(0.0, double.infinity);
    final double adjMaxWeight = maxWeight + weightRange * 0.1;
    final double adjRangeWeight = adjMaxWeight - adjMinWeight;

    // Déterminer la chronologie globale (minDate & maxDate)
    final allDates = [
      ...perfPoints.map((p) => p['date'] as DateTime),
      ...weightPoints.map((p) => p['date'] as DateTime),
    ];
    allDates.sort();

    final DateTime minDate = allDates.first;
    final DateTime maxDate = allDates.last;
    final int totalDurationMs = maxDate.difference(minDate).inMilliseconds;
    final double timeSpanMs = totalDurationMs == 0 ? 1.0 : totalDurationMs.toDouble();

    // Peintres de texte et lignes
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final gridPaint = Paint()
      ..color = const Color(0xff2d2d34)
      ..strokeWidth = 0.8;

    // 1. Grille et graduations Y
    for (int i = 0; i <= 3; i++) {
      final double ratio = i / 3.0;
      final double y = paddingTop + chartHeight * (1.0 - ratio);

      canvas.drawLine(Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);

      // Valeur axe Force (gauche)
      final forceVal = adjMinPerf + ratio * adjRangePerf;
      textPainter.text = TextSpan(
        text: "${forceVal.toStringAsFixed(0)}kg",
        style: const TextStyle(color: Color(0xff3b82f6), fontSize: 8, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 4, y - textPainter.height / 2));

      // Valeur axe Poids (droite)
      final weightVal = adjMinWeight + ratio * adjRangeWeight;
      textPainter.text = TextSpan(
        text: "${weightVal.toStringAsFixed(0)}kg",
        style: const TextStyle(color: Color(0xff10b981), fontSize: 8, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - paddingRight + 4, y - textPainter.height / 2));
    }

    // 2. Tracer la courbe de Poids Corporel (Vert)
    if (weightPoints.isNotEmpty) {
      final List<Offset> wOffsets = [];
      for (var p in weightPoints) {
        final d = p['date'] as DateTime;
        final v = p['value'] as double;
        final double x = totalDurationMs == 0
            ? paddingLeft + chartWidth / 2
            : paddingLeft + (d.difference(minDate).inMilliseconds / timeSpanMs) * chartWidth;
        final double y = paddingTop + chartHeight - ((v - adjMinWeight) / adjRangeWeight) * chartHeight;
        wOffsets.add(Offset(x, y));
      }

      final wLinePaint = Paint()
        ..color = const Color(0xff10b981)
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      final wPath = Path()..moveTo(wOffsets.first.dx, wOffsets.first.dy);
      for (int i = 1; i < wOffsets.length; i++) {
        wPath.lineTo(wOffsets[i].dx, wOffsets[i].dy);
      }
      canvas.drawPath(wPath, wLinePaint);

      final wDotPaint = Paint()..color = const Color(0xff10b981)..style = PaintingStyle.fill;
      for (var pt in wOffsets) {
        canvas.drawCircle(pt, 3.5, wDotPaint);
      }
    }

    // 3. Tracer la courbe de Force / 1RM (Bleu)
    if (perfPoints.isNotEmpty) {
      final List<Offset> pOffsets = [];
      for (var p in perfPoints) {
        final d = p['date'] as DateTime;
        final v = p['value'] as double;
        final double x = totalDurationMs == 0
            ? paddingLeft + chartWidth / 2
            : paddingLeft + (d.difference(minDate).inMilliseconds / timeSpanMs) * chartWidth;
        final double y = paddingTop + chartHeight - ((v - adjMinPerf) / adjRangePerf) * chartHeight;
        pOffsets.add(Offset(x, y));
      }

      final pLinePaint = Paint()
        ..color = const Color(0xff3b82f6)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;

      final pPath = Path()..moveTo(pOffsets.first.dx, pOffsets.first.dy);
      for (int i = 1; i < pOffsets.length; i++) {
        pPath.lineTo(pOffsets[i].dx, pOffsets[i].dy);
      }
      canvas.drawPath(pPath, pLinePaint);

      final pDotPaint = Paint()..color = const Color(0xff3b82f6)..style = PaintingStyle.fill;
      final whiteCenter = Paint()..color = Colors.white..style = PaintingStyle.fill;
      for (var pt in pOffsets) {
        canvas.drawCircle(pt, 4.5, pDotPaint);
        canvas.drawCircle(pt, 2.0, whiteCenter);
      }
    }

    // 4. Dates sur l'axe horizontal X
    final startStr = DateFormat('dd MMM', 'fr_FR').format(minDate);
    final endStr = DateFormat('dd MMM', 'fr_FR').format(maxDate);

    textPainter.text = TextSpan(text: startStr, style: TextStyle(color: Colors.grey[500], fontSize: 8));
    textPainter.layout();
    textPainter.paint(canvas, Offset(paddingLeft, paddingTop + chartHeight + 6));

    if (startStr != endStr) {
      textPainter.text = TextSpan(text: endStr, style: TextStyle(color: Colors.grey[500], fontSize: 8));
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - paddingRight - textPainter.width, paddingTop + chartHeight + 6));
    }
  }

  @override
  bool shouldRepaint(covariant DualAxisPainter oldDelegate) {
    return oldDelegate.perfPoints != perfPoints || oldDelegate.weightPoints != weightPoints;
  }
}
