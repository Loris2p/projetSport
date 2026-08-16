import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../models/body_measurement.dart';
import '../providers/workout_provider.dart';
import '../theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _uuid = const Uuid();
  
  // Exercise progression chart state
  String? _selectedExerciseId;
  bool _showEstimated1RM = false; // false = Max Weight, true = Estimated 1RM

  // Body stats state
  String _selectedBodyMetric = 'weight'; // 'weight', 'fat', 'muscle', 'water', 'bmi'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
            Tab(icon: Icon(Icons.accessibility_new_rounded), text: "Corporel"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExercisesTab(workoutProvider, performedExercises),
          _buildSessionsTab(workoutProvider, history),
          _buildBodyStatsTab(workoutProvider),
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

  // ==================== ONGLET CORPOREL (STATS CORPORELLES) ====================

  Widget _buildBodyStatsTab(WorkoutProvider provider) {
    final measurements = provider.bodyMeasurements;

    if (measurements.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.athleticBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.accessibility_new_rounded, size: 48, color: AppTheme.athleticBlue),
              ),
              const SizedBox(height: 20),
              const Text(
                "Aucune mesure corporelle",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Suivez l'évolution de votre corps : poids, taille, % de masse grasse, masse musculaire et masse hydrique.",
                style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditMeasurementModal(context),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Enregistrer ma première mesure", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.athleticBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final latest = measurements.first;
    final previous = measurements.length > 1 ? measurements[1] : null;

    // Timeline data for selected metric (sorted oldest to newest for graph)
    final chronologicalMeasurements = measurements.reversed.toList();
    final List<Map<String, dynamic>> metricData = [];

    for (var m in chronologicalMeasurements) {
      double? val;
      switch (_selectedBodyMetric) {
        case 'weight':
          val = m.weight;
          break;
        case 'fat':
          val = m.bodyFatPercentage;
          break;
        case 'muscle':
          val = m.musclePercentage;
          break;
        case 'water':
          val = m.waterPercentage;
          break;
        case 'bmi':
          val = m.bmi;
          break;
      }
      if (val != null) {
        metricData.add({
          'date': m.date,
          'value': val,
        });
      }
    }

    final values = metricData.map((d) => (d['value'] as num).toDouble()).toList();
    final dates = metricData.map((d) => d['date'] as DateTime).toList();

    // Determine current metric metadata (label, unit, color)
    final String metricName;
    final String metricUnit;
    final Color metricColor;
    switch (_selectedBodyMetric) {
      case 'fat':
        metricName = "Masse grasse";
        metricUnit = "%";
        metricColor = const Color(0xfff59e0b); // Amber
        break;
      case 'muscle':
        metricName = "Masse musculaire";
        metricUnit = "%";
        metricColor = const Color(0xff10b981); // Emerald
        break;
      case 'water':
        metricName = "Masse hydrique (Eau)";
        metricUnit = "%";
        metricColor = const Color(0xff06b6d4); // Cyan
        break;
      case 'bmi':
        metricName = "Indice de Masse Corporelle (IMC)";
        metricUnit = "";
        metricColor = const Color(0xff8b5cf6); // Purple
        break;
      case 'weight':
      default:
        metricName = "Poids corporel";
        metricUnit = "kg";
        metricColor = AppTheme.athleticBlue; // Blue
        break;
    }

    // Key figures for selected metric
    final double? currentVal = values.isNotEmpty ? values.last : null;
    final double? minVal = values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : null;
    final double? maxVal = values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : null;
    final double? avgVal = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : null;
    final double? deltaTotal = values.length >= 2 ? values.last - values.first : null;

    // Weight delta with previous measurement
    double? weightDelta;
    if (latest.weight != null && previous?.weight != null) {
      weightDelta = latest.weight! - previous!.weight!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header summary & Add button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Dernières mesures",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditMeasurementModal(context),
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text("Nouvelle mesure", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.athleticBlue,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overview Cards Grid
          Row(
            children: [
              // Poids
              Expanded(
                child: _buildMetricOverviewCard(
                  title: "Poids actuel",
                  value: latest.weight != null ? "${latest.weight!.toStringAsFixed(1)} kg" : "--",
                  subValue: weightDelta != null
                      ? "${weightDelta >= 0 ? '+' : ''}${weightDelta.toStringAsFixed(1)} kg vs préc."
                      : (latest.height != null ? "${latest.height!.toStringAsFixed(0)} cm" : null),
                  subValueColor: weightDelta != null
                      ? (weightDelta < 0 ? const Color(0xff10b981) : Colors.amber)
                      : Colors.grey,
                  icon: Icons.monitor_weight_outlined,
                  color: AppTheme.athleticBlue,
                  onTap: () => setState(() => _selectedBodyMetric = 'weight'),
                  isSelected: _selectedBodyMetric == 'weight',
                ),
              ),
              const SizedBox(width: 8),
              // IMC
              Expanded(
                child: _buildMetricOverviewCard(
                  title: "IMC",
                  value: latest.bmi != null ? latest.bmi!.toStringAsFixed(1) : "--",
                  subValue: latest.bmiCategory ?? (latest.height == null ? "Ajouter taille" : null),
                  subValueColor: _getBmiColor(latest.bmi),
                  icon: Icons.health_and_safety_outlined,
                  color: const Color(0xff8b5cf6),
                  onTap: () => setState(() => _selectedBodyMetric = 'bmi'),
                  isSelected: _selectedBodyMetric == 'bmi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // % Masse grasse
              Expanded(
                child: _buildMetricOverviewCard(
                  title: "Masse grasse",
                  value: latest.bodyFatPercentage != null ? "${latest.bodyFatPercentage!.toStringAsFixed(1)}%" : "--",
                  subValue: latest.fatMassKg != null ? "${latest.fatMassKg!.toStringAsFixed(1)} kg" : null,
                  icon: Icons.pie_chart_outline,
                  color: const Color(0xfff59e0b),
                  onTap: () => setState(() => _selectedBodyMetric = 'fat'),
                  isSelected: _selectedBodyMetric == 'fat',
                ),
              ),
              const SizedBox(width: 8),
              // % Masse musculaire
              Expanded(
                child: _buildMetricOverviewCard(
                  title: "Masse musculaire",
                  value: latest.musclePercentage != null ? "${latest.musclePercentage!.toStringAsFixed(1)}%" : "--",
                  subValue: latest.muscleMassKg != null ? "${latest.muscleMassKg!.toStringAsFixed(1)} kg" : null,
                  icon: Icons.fitness_center_rounded,
                  color: const Color(0xff10b981),
                  onTap: () => setState(() => _selectedBodyMetric = 'muscle'),
                  isSelected: _selectedBodyMetric == 'muscle',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // % Masse hydrique
              Expanded(
                child: _buildMetricOverviewCard(
                  title: "Masse hydrique (Eau)",
                  value: latest.waterPercentage != null ? "${latest.waterPercentage!.toStringAsFixed(1)}%" : "--",
                  subValue: latest.waterMassKg != null ? "${latest.waterMassKg!.toStringAsFixed(1)} L" : null,
                  icon: Icons.water_drop_outlined,
                  color: const Color(0xff06b6d4),
                  onTap: () => setState(() => _selectedBodyMetric = 'water'),
                  isSelected: _selectedBodyMetric == 'water',
                ),
              ),
              const SizedBox(width: 8),
              // Taille & Date
              Expanded(
                child: _buildMetricOverviewCard(
                  title: "Dernière pesée",
                  value: DateFormat('dd/MM/yyyy').format(latest.date),
                  subValue: latest.height != null ? "Taille: ${latest.height!.toStringAsFixed(0)} cm" : (latest.note ?? ""),
                  icon: Icons.calendar_today_outlined,
                  color: Colors.tealAccent,
                  onTap: null,
                  isSelected: false,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Section Graphique
          const Text(
            "Évolution graphique",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 10),

          // Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBodyMetricChip('weight', '⚖️ Poids', AppTheme.athleticBlue),
                const SizedBox(width: 8),
                _buildBodyMetricChip('fat', '📉 % Graisse', const Color(0xfff59e0b)),
                const SizedBox(width: 8),
                _buildBodyMetricChip('muscle', '💪 % Muscle', const Color(0xff10b981)),
                const SizedBox(width: 8),
                _buildBodyMetricChip('water', '💧 % Eau', const Color(0xff06b6d4)),
                const SizedBox(width: 8),
                _buildBodyMetricChip('bmi', '📊 IMC', const Color(0xff8b5cf6)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Card du graphique
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
                      metricName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    ),
                    if (currentVal != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: metricColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: metricColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          "${currentVal.toStringAsFixed(1)} $metricUnit",
                          style: TextStyle(color: metricColor, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (values.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(
                      child: Text(
                        "Aucune donnée enregistrée pour cette métrique.\nAjoutez ou modifiez une pesée pour renseigner cette valeur.",
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  CustomLineChart(
                    values: values,
                    dates: dates,
                    unit: metricUnit,
                    color: metricColor,
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.darkBorder, height: 1),
                  const SizedBox(height: 12),
                  // KPI pills row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildChartStatItem("Min", minVal != null ? "${minVal.toStringAsFixed(1)} $metricUnit" : "--"),
                      _buildChartStatItem("Moy.", avgVal != null ? "${avgVal.toStringAsFixed(1)} $metricUnit" : "--"),
                      _buildChartStatItem("Max", maxVal != null ? "${maxVal.toStringAsFixed(1)} $metricUnit" : "--"),
                      _buildChartStatItem(
                        "Évolution",
                        deltaTotal != null
                            ? "${deltaTotal >= 0 ? '+' : ''}${deltaTotal.toStringAsFixed(1)} $metricUnit"
                            : "--",
                        valueColor: deltaTotal == null
                            ? Colors.white
                            : (_selectedBodyMetric == 'fat' || _selectedBodyMetric == 'weight'
                                ? (deltaTotal <= 0 ? const Color(0xff10b981) : Colors.amber)
                                : (deltaTotal >= 0 ? const Color(0xff10b981) : Colors.amber)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section Historique
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Historique des pesées (${measurements.length})",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Liste des mesures
          ...measurements.map((measurement) {
            return _buildMeasurementHistoryTile(context, provider, measurement);
          }),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBodyMetricChip(String key, String label, Color color) {
    final isSelected = _selectedBodyMetric == key;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: AppTheme.darkSurface,
      side: BorderSide(
        color: isSelected ? color : AppTheme.darkBorder,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _selectedBodyMetric = key),
    );
  }

  Widget _buildMetricOverviewCard({
    required String title,
    required String value,
    String? subValue,
    Color? subValueColor,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.darkBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subValue != null && subValue.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subValue,
                style: TextStyle(
                  color: subValueColor ?? Colors.grey[400],
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartStatItem(String label, String value, {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Color _getBmiColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25.0) return const Color(0xff10b981); // Normal (Green)
    if (bmi < 30.0) return Colors.amber; // Overweight (Amber)
    return Colors.redAccent; // Obese (Red)
  }

  Widget _buildMeasurementHistoryTile(
    BuildContext context,
    WorkoutProvider provider,
    BodyMeasurement measurement,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppTheme.athleticBlue),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(measurement.date),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: (action) {
                  if (action == 'edit') {
                    _showAddOrEditMeasurementModal(context, measurement: measurement);
                  } else if (action == 'delete') {
                    _confirmDeleteMeasurement(context, provider, measurement.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text("Modifier"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Badges row
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (measurement.weight != null)
                _buildTagChip("⚖️ ${measurement.weight!.toStringAsFixed(1)} kg", AppTheme.athleticBlue),
              if (measurement.height != null)
                _buildTagChip("📏 ${measurement.height!.toStringAsFixed(0)} cm", Colors.teal),
              if (measurement.bmi != null)
                _buildTagChip("📊 IMC ${measurement.bmi!.toStringAsFixed(1)}", _getBmiColor(measurement.bmi)),
              if (measurement.bodyFatPercentage != null)
                _buildTagChip("📉 Graisse ${measurement.bodyFatPercentage!.toStringAsFixed(1)}%", const Color(0xfff59e0b)),
              if (measurement.musclePercentage != null)
                _buildTagChip("💪 Muscle ${measurement.musclePercentage!.toStringAsFixed(1)}%", const Color(0xff10b981)),
              if (measurement.waterPercentage != null)
                _buildTagChip("💧 Eau ${measurement.waterPercentage!.toStringAsFixed(1)}%", const Color(0xff06b6d4)),
              if (measurement.boneMass != null)
                _buildTagChip("🦴 Os ${measurement.boneMass!.toStringAsFixed(1)} kg", Colors.blueGrey),
            ],
          ),
          if (measurement.note != null && measurement.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Note : ${measurement.note}",
              style: TextStyle(color: Colors.grey[400], fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _confirmDeleteMeasurement(BuildContext context, WorkoutProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text("Supprimer la mesure ?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Cette action est irréversible. Les données de cette pesée seront supprimées.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteBodyMeasurement(id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Mesure corporelle supprimée")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditMeasurementModal(BuildContext context, {BodyMeasurement? measurement}) {
    final isEditing = measurement != null;
    final provider = context.read<WorkoutProvider>();

    // Pre-fill height from latest measurement if available and creating new
    final latestHeight = measurement?.height ?? provider.latestBodyMeasurement?.height;

    DateTime selectedDate = measurement?.date ?? DateTime.now();
    final weightController = TextEditingController(text: measurement?.weight?.toString() ?? '');
    final heightController = TextEditingController(text: latestHeight?.toString() ?? '');
    final fatController = TextEditingController(text: measurement?.bodyFatPercentage?.toString() ?? '');
    final muscleController = TextEditingController(text: measurement?.musclePercentage?.toString() ?? '');
    final waterController = TextEditingController(text: measurement?.waterPercentage?.toString() ?? '');
    final boneController = TextEditingController(text: measurement?.boneMass?.toString() ?? '');
    final noteController = TextEditingController(text: measurement?.note ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalContext, setModalState) {
          // Dynamic IMC preview
          final double? curWeight = double.tryParse(weightController.text.replaceAll(',', '.'));
          final double? curHeight = double.tryParse(heightController.text.replaceAll(',', '.'));
          double? calculatedBmi;
          String? bmiCategory;
          if (curWeight != null && curHeight != null && curHeight > 0) {
            final hM = curHeight / 100.0;
            calculatedBmi = curWeight / (hM * hM);
            if (calculatedBmi < 18.5) {
              bmiCategory = 'Insuffisance pondérale';
            } else if (calculatedBmi < 25.0) {
              bmiCategory = 'Corpulence normale';
            } else if (calculatedBmi < 30.0) {
              bmiCategory = 'Surpoids';
            } else {
              bmiCategory = 'Obésité';
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? "Modifier la pesée" : "Nouvelle mesure corporelle",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(modalContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date picker selector
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: modalContext,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 1)),
                        builder: (c, child) => Theme(
                          data: Theme.of(c).copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: AppTheme.athleticBlue,
                              surface: AppTheme.darkSurface,
                            ),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.darkBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month, color: AppTheme.athleticBlue, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(selectedDate),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Row: Poids & Taille
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: weightController,
                          label: "Poids (kg) *",
                          hint: "ex: 75.5",
                          icon: Icons.monitor_weight_outlined,
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          controller: heightController,
                          label: "Taille (cm)",
                          hint: "ex: 180",
                          icon: Icons.height_rounded,
                          onChanged: (_) => setModalState(() {}),
                        ),
                      ),
                    ],
                  ),

                  // IMC Preview banner if available
                  if (calculatedBmi != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _getBmiColor(calculatedBmi).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getBmiColor(calculatedBmi).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: _getBmiColor(calculatedBmi)),
                          const SizedBox(width: 8),
                          Text(
                            "IMC estimé : ${calculatedBmi.toStringAsFixed(1)} ($bmiCategory)",
                            style: TextStyle(
                              color: _getBmiColor(calculatedBmi),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Row: % Graisse & % Muscle
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: fatController,
                          label: "Masse grasse (%)",
                          hint: "ex: 15.0",
                          icon: Icons.pie_chart_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          controller: muscleController,
                          label: "Masse musculaire (%)",
                          hint: "ex: 42.5",
                          icon: Icons.fitness_center_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Row: % Eau & Masse osseuse
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: waterController,
                          label: "Masse hydrique / Eau (%)",
                          hint: "ex: 58.0",
                          icon: Icons.water_drop_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          controller: boneController,
                          label: "Masse osseuse (kg)",
                          hint: "ex: 3.2",
                          icon: Icons.accessibility_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Notes
                  _buildInputField(
                    controller: noteController,
                    label: "Notes / Contexte",
                    hint: "ex: Pesée à jeun au réveil",
                    icon: Icons.edit_note,
                    isText: true,
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final weight = double.tryParse(weightController.text.trim().replaceAll(',', '.'));
                        final height = double.tryParse(heightController.text.trim().replaceAll(',', '.'));
                        final fat = double.tryParse(fatController.text.trim().replaceAll(',', '.'));
                        final muscle = double.tryParse(muscleController.text.trim().replaceAll(',', '.'));
                        final water = double.tryParse(waterController.text.trim().replaceAll(',', '.'));
                        final bone = double.tryParse(boneController.text.trim().replaceAll(',', '.'));
                        final note = noteController.text.trim().isEmpty ? null : noteController.text.trim();

                        if (weight == null && fat == null && muscle == null && water == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Veuillez renseigner au moins une valeur (poids, %, etc.).")),
                          );
                          return;
                        }

                        final newMeasurement = BodyMeasurement(
                          id: measurement?.id ?? _uuid.v4(),
                          date: selectedDate,
                          weight: weight,
                          height: height,
                          bodyFatPercentage: fat,
                          musclePercentage: muscle,
                          waterPercentage: water,
                          boneMass: bone,
                          note: note,
                        );

                        await provider.saveBodyMeasurement(newMeasurement);

                        if (modalContext.mounted) {
                          Navigator.pop(modalContext);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(isEditing ? "Pesée mise à jour !" : "Nouvelle pesée enregistrée !")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.athleticBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isEditing ? "Enregistrer les modifications" : "Ajouter la pesée",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isText = false,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: isText ? TextInputType.text : const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
            prefixIcon: Icon(icon, color: Colors.grey[500], size: 18),
            filled: true,
            fillColor: AppTheme.darkSurface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.darkBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.darkBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.athleticBlue, width: 1.5),
            ),
          ),
        ),
      ],
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
  final Color color;

  const CustomLineChart({
    super.key,
    required this.values,
    required this.dates,
    required this.unit,
    this.color = const Color(0xff2563eb),
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
          color: color,
        ),
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<DateTime> dates;
  final String unit;
  final Color color;

  LineChartPainter({
    required this.values,
    required this.dates,
    required this.unit,
    this.color = const Color(0xff2563eb),
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
        ..shader = LinearGradient(
          colors: [
            color.withOpacity(0.25),
            color.withOpacity(0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, size.width - paddingRight, size.height - paddingBottom))
        ..style = PaintingStyle.fill;

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw connection line
    final linePaint = Paint()
      ..color = color
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
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final pt = points[i];

      // Draw ring & white center dot
      canvas.drawCircle(pt, 5.5, ringPaint);
      canvas.drawCircle(pt, 2.5, centerDotPaint);

      // Label showing date (horizontal axis)
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

      // Draw value tag above point
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
          Paint()..color = color..style = PaintingStyle.fill,
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
    return oldDelegate.values != values || oldDelegate.dates != dates || oldDelegate.unit != unit || oldDelegate.color != color;
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
