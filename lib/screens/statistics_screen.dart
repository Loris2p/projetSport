import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../providers/workout_provider.dart';
import '../theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Exercise progression chart state
  String? _selectedExerciseId;
  bool _showEstimated1RM = false; // false = Max Weight, true = Estimated 1RM

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final history = workoutProvider.history;

    // List of exercises that have at least one validated set in history
    final Set<String> performedExerciseIds = {};
    for (var session in history) {
      for (var ex in session.exercises) {
        if (ex.sets.any((s) => s.isCompleted)) {
          performedExerciseIds.add(ex.exerciseId);
        }
      }
    }

    final performedExercises = workoutProvider.exercises
        .where((e) => performedExerciseIds.contains(e.id))
        .toList();

    // Default select the first exercise if not set or if no longer in the list
    if (performedExercises.isNotEmpty) {
      if (_selectedExerciseId == null || !performedExerciseIds.contains(_selectedExerciseId)) {
        _selectedExerciseId = performedExercises.first.id;
      }
    } else {
      _selectedExerciseId = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analyses & Stats"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.athleticBlue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.show_chart), text: "Exercices"),
            Tab(icon: Icon(Icons.bar_chart), text: "Séances"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExercisesTab(workoutProvider, performedExercises),
          _buildSessionsTab(workoutProvider, history),
        ],
      ),
    );
  }

  // ==================== ONGLET EXERCICES (PROGRESSION) ====================

  Widget _buildExercisesTab(WorkoutProvider provider, List<Exercise> performedExercises) {
    if (performedExercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              const Text(
                "Pas encore de données d'entraînement",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Terminez une séance avec des séries validées pour commencer à suivre votre progression graphique.",
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final selectedExercise = performedExercises.firstWhere((e) => e.id == _selectedExerciseId);

    // Build timeline data for selected exercise
    final List<Map<String, dynamic>> timelineData = [];
    final history = provider.history;

    // We process from oldest to newest to draw the curve chronologically
    for (var session in history.reversed) {
      for (var perfEx in session.exercises) {
        if (perfEx.exerciseId == _selectedExerciseId) {
          final completedSets = perfEx.sets.where((s) => s.isCompleted).toList();
          if (completedSets.isNotEmpty) {
            double maxValue = 0;
            if (_showEstimated1RM) {
              // Find max estimated 1RM
              maxValue = completedSets.map((s) => s.estimated1RM).reduce((a, b) => a > b ? a : b);
            } else {
              // Find max weight
              maxValue = completedSets.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
            }

            timelineData.add({
              'date': session.startTime,
              'value': maxValue,
              'setsCount': completedSets.length,
            });
          }
        }
      }
    }

    final values = timelineData.map((d) => d['value'] as double).toList();
    final dates = timelineData.map((d) => d['date'] as DateTime).toList();

    // Stats all-time
    double maxAllTime = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    int totalSets = timelineData.fold(0, (sum, item) => sum + (item['setsCount'] as int));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Select exercise card
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedExerciseId,
                  isExpanded: true,
                  dropdownColor: AppTheme.darkSurface,
                  hint: const Text("Sélectionner un exercice"),
                  onChanged: (newId) {
                    setState(() {
                      _selectedExerciseId = newId;
                    });
                  },
                  items: performedExercises.map((ex) {
                    return DropdownMenuItem<String>(
                      value: ex.id,
                      child: Row(
                        children: [
                          const Icon(Icons.fitness_center, color: AppTheme.athleticBlue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                          Text(ex.category, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Metric toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ToggleButtons(
                borderRadius: BorderRadius.circular(10),
                selectedColor: Colors.white,
                fillColor: AppTheme.athleticBlue,
                color: Colors.grey,
                constraints: const BoxConstraints(minHeight: 38, minWidth: 150),
                isSelected: [!_showEstimated1RM, _showEstimated1RM],
                onPressed: (index) {
                  setState(() {
                    _showEstimated1RM = index == 1;
                  });
                },
                children: const [
                  Text("Charge Max (kg)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  Text("1RM Estimé (kg)", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main line chart container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showEstimated1RM ? "Progression du 1RM" : "Evolution de charge max",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                    ),
                    Text(
                      selectedExercise.name,
                      style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Divider(height: 24),
                CustomLineChart(
                  values: values,
                  dates: dates,
                  unit: "kg",
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // All-time metrics row
          Row(
            children: [
              Expanded(
                child: _buildSimpleMetricTile(
                  label: _showEstimated1RM ? "Meilleur 1RM" : "Charge Max Record",
                  value: "${maxAllTime.toStringAsFixed(1).replaceAll('.0', '')} kg",
                  icon: Icons.emoji_events,
                  iconColor: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSimpleMetricTile(
                  label: "Séries Validées",
                  value: "$totalSets",
                  icon: Icons.check_circle_outline,
                  iconColor: AppTheme.greenCheck,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // History of progression data table
          const Text(
            "Historique des performances",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: timelineData.length,
            itemBuilder: (context, index) {
              // Show newest first
              final data = timelineData[timelineData.length - 1 - index];
              final dateStr = DateFormat('dd MMMM yyyy', 'fr_FR').format(data['date'] as DateTime);
              final valStr = (data['value'] as double).toStringAsFixed(1).replaceAll('.0', '');

              return Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    backgroundColor: Colors.white10,
                    radius: 16,
                    child: Icon(Icons.trending_up, color: AppTheme.athleticBlue, size: 16),
                  ),
                  title: Text(
                    "$valStr kg",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  subtitle: Text(dateStr, style: const TextStyle(color: Colors.grey)),
                  trailing: Text(
                    "${data['setsCount']} séries",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==================== ONGLET SEANCES (VOLUME & REPARTITION) ====================

  Widget _buildSessionsTab(WorkoutProvider provider, List<WorkoutSession> history) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              const Text(
                "Historique vide",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Enregistrez des séances d'entraînement pour consulter le volume et la répartition musculaire.",
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // 1. Data for session volume bar chart (last 7 workouts)
    final recentSessions = history.take(7).toList().reversed.toList();
    final List<double> volumes = [];
    final List<String> labels = [];

    for (var session in recentSessions) {
      volumes.add(provider.calculateSessionVolume(session));
      labels.add(DateFormat('d MMM', 'fr_FR').format(session.startTime));
    }

    // 2. Data for Muscle group distribution
    final Map<String, int> setsPerCategory = {};
    int totalSetsAllTime = 0;

    for (var session in history) {
      for (var perfEx in session.exercises) {
        final exercise = provider.exercises.firstWhere(
          (e) => e.id == perfEx.exerciseId,
          orElse: () => Exercise(id: perfEx.exerciseId, name: 'Inconnu', category: 'Autre'),
        );
        final completedSetsCount = perfEx.sets.where((s) => s.isCompleted).length;
        if (completedSetsCount > 0) {
          setsPerCategory[exercise.category] = (setsPerCategory[exercise.category] ?? 0) + completedSetsCount;
          totalSetsAllTime += completedSetsCount;
        }
      }
    }

    final sortedCategories = setsPerCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 3. Stats general summary
    double totalVolumeTons = 0;
    int sessionsWithHealthSync = 0;
    double totalCalories = 0;
    double heartRateSum = 0;
    int heartRateSessionsCount = 0;

    for (var session in history) {
      totalVolumeTons += provider.calculateSessionVolume(session) / 1000.0;
      if (session.activeCaloriesBurned != null) {
        totalCalories += session.activeCaloriesBurned!;
        sessionsWithHealthSync++;
      }
      if (session.averageHeartRate != null) {
        heartRateSum += session.averageHeartRate!;
        heartRateSessionsCount++;
      }
    }

    double avgCalories = sessionsWithHealthSync > 0 ? totalCalories / sessionsWithHealthSync : 0.0;
    double avgHeartRate = heartRateSessionsCount > 0 ? heartRateSum / heartRateSessionsCount : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Volume chart container
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Volume Déplacé par Séance",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                    ),
                    Text(
                      "7 derniers entraînements",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const Divider(height: 24),
                VolumeBarChart(volumes: volumes, labels: labels),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Muscle distribution card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.darkBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Répartition par Groupe Musculaire",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70),
                ),
                const Text(
                  "Basé sur le nombre de séries complétées",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const Divider(height: 24),
                if (totalSetsAllTime == 0)
                  const Center(child: Text("Aucune série validée pour le moment", style: TextStyle(color: Colors.grey)))
                else
                  ...sortedCategories.map((entry) {
                    final categoryName = entry.key;
                    final setsCount = entry.value;
                    final double percentage = totalSetsAllTime > 0 ? setsCount / totalSetsAllTime : 0.0;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(categoryName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(
                                "${(percentage * 100).toStringAsFixed(0)}% ($setsCount séries)",
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              backgroundColor: AppTheme.darkBorder,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getCategoryColor(categoryName),
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // General stats grids
          const Text("Statistiques Globales", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _buildGeneralStatCard(
                title: "Entraînements",
                value: "${history.length}",
                icon: Icons.fitness_center,
                color: Colors.purpleAccent,
              ),
              _buildGeneralStatCard(
                title: "Volume Total",
                value: "${totalVolumeTons.toStringAsFixed(1)} T",
                icon: Icons.insights,
                color: Colors.orangeAccent,
              ),
              _buildGeneralStatCard(
                title: "Moy. Calories",
                value: avgCalories > 0 ? "${avgCalories.round()} kcal" : "--",
                icon: Icons.local_fire_department,
                color: Colors.redAccent,
              ),
              _buildGeneralStatCard(
                title: "Moy. Cardiaque",
                value: avgHeartRate > 0 ? "${avgHeartRate.round()} bpm" : "--",
                icon: Icons.favorite,
                color: Colors.pinkAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== WIDGETS HELPERS ====================

  Widget _buildSimpleMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGeneralStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Pectoraux':
        return Colors.blue;
      case 'Dos':
        return Colors.green;
      case 'Jambes':
        return Colors.orange;
      case 'Épaules':
        return Colors.red;
      case 'Bras':
        return Colors.purple;
      case 'Abdominaux':
        return Colors.teal;
      case 'Cardio':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}

// ==================== CUSTOM PAINTER FOR LINE CHART ====================

class CustomLineChart extends StatelessWidget {
  final List<double> values;
  final List<DateTime> dates;
  final String unit;

  const CustomLineChart({
    super.key,
    required this.values,
    required this.dates,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            "Aucune donnée d'entraînement.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: CustomPaint(
        size: Size.infinite,
        painter: LineChartPainter(
          values: values,
          dates: dates,
          unit: unit,
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<DateTime> dates;
  final String unit;

  LineChartPainter({
    required this.values,
    required this.dates,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double maxVal = values.reduce((a, b) => a > b ? a : b);
    final double minVal = values.reduce((a, b) => a < b ? a : b);
    
    // Safety range division
    final double valRange = (maxVal - minVal) == 0 ? 10.0 : (maxVal - minVal);
    final double absoluteMin = (minVal - valRange * 0.1).clamp(0.0, double.infinity);
    final double absoluteMax = maxVal + valRange * 0.1;
    final double adjustedRange = absoluteMax - absoluteMin;

    const double paddingLeft = 40.0;
    const double paddingRight = 16.0;
    const double paddingTop = 20.0;
    const double paddingBottom = 20.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingTop - paddingBottom;

    if (chartWidth <= 0 || chartHeight <= 0) return;

    // Draw horizontal grid lines
    final gridPaint = Paint()
      ..color = const Color(0xff2d2d34)
      ..strokeWidth = 0.8;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw grid lines
    final gridValues = [absoluteMin, absoluteMin + adjustedRange / 2, absoluteMax];
    for (int i = 0; i < 3; i++) {
      final double val = gridValues[i];
      final double y = paddingTop + chartHeight - ((val - absoluteMin) / adjustedRange) * chartHeight;

      // Draw dashed-like grid line
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Value label on the left
      textPainter.text = TextSpan(
        text: "${val.toStringAsFixed(0)} $unit",
        style: TextStyle(color: Colors.grey[500], fontSize: 8),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2),
      );
    }

    // Map points to screen coordinates
    final List<Offset> points = [];
    final int count = values.length;
    for (int i = 0; i < count; i++) {
      final double x = paddingLeft + (count == 1 ? chartWidth / 2 : (i / (count - 1)) * chartWidth);
      final double y = paddingTop + chartHeight - ((values[i] - absoluteMin) / adjustedRange) * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw area gradient fill
    if (points.length > 1) {
      final Path fillPath = Path();
      fillPath.moveTo(points.first.dx, paddingTop + chartHeight);
      for (var point in points) {
        fillPath.lineTo(point.dx, point.dy);
      }
      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x222563eb), // Transparent primary blue
            Color(0x002563eb),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, size.width - paddingRight, size.height - paddingBottom))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw connection line
    final linePaint = Paint()
      ..color = const Color(0xff2563eb)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Path linePath = Path();
    if (points.isNotEmpty) {
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    // Draw dots and value tags
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = const Color(0xff2563eb)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final pt = points[i];

      // Draw blue ring & white center dot
      canvas.drawCircle(pt, 5.5, ringPaint);
      canvas.drawCircle(pt, 2.5, centerDotPaint);

      // Label showing date (horizontal axis)
      // Only display labels strategically if there are many points to avoid overlaps
      if (count <= 7 || i == 0 || i == count - 1 || i == count ~/ 2) {
        final dateStr = DateFormat('dd MMM', 'fr_FR').format(dates[i]);
        textPainter.text = TextSpan(
          text: dateStr,
          style: TextStyle(color: Colors.grey[400], fontSize: 8),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(pt.dx - textPainter.width / 2, paddingTop + chartHeight + 6),
        );
      }

      // Draw weight tag above point
      if (count <= 8 || i == 0 || i == count - 1 || values[i] == maxVal) {
        final valText = values[i].toStringAsFixed(1).replaceAll('.0', '');
        textPainter.text = TextSpan(
          text: valText,
          style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
        );
        textPainter.layout();
        
        // Draw small bubble background
        final bubbleRect = Rect.fromLTWH(
          pt.dx - textPainter.width / 2 - 3,
          pt.dy - textPainter.height - 7,
          textPainter.width + 6,
          textPainter.height + 3,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(bubbleRect, const Radius.circular(4)),
          Paint()..color = const Color(0xff2563eb)..style = PaintingStyle.fill,
        );

        textPainter.paint(
          canvas,
          Offset(pt.dx - textPainter.width / 2, pt.dy - textPainter.height - 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.dates != dates || oldDelegate.unit != unit;
  }
}

// ==================== CUSTOM BAR CHART FOR VOLUME ====================

class VolumeBarChart extends StatelessWidget {
  final List<double> volumes;
  final List<String> labels;

  const VolumeBarChart({
    super.key,
    required this.volumes,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    if (volumes.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: Text(
            "Aucun entraînement.",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    final double maxVol = volumes.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(volumes.length, (idx) {
          final vol = volumes[idx];
          final label = labels[idx];
          final double percent = maxVol > 0 ? vol / maxVol : 0.0;
          final double volTons = vol / 1000.0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    volTons > 0 ? "${volTons.toStringAsFixed(1)}T" : "0",
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: AppTheme.athleticBlue),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: (percent * 85).clamp(4.0, 85.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff2563eb), Color(0xff7c3aed)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
