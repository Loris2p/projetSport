import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../models/exercise_set.dart';
import '../providers/workout_provider.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final history = workoutProvider.history;

    if (history.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Historique")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey[600]),
              const SizedBox(height: 16),
              const Text(
                "Aucun entraînement enregistré",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Vos séances passées apparaîtront ici.",
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    final flatItems = workoutProvider.flatHistory;

    return Scaffold(
      appBar: AppBar(title: const Text("Historique")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: flatItems.length,
        itemBuilder: (context, index) {
          final item = flatItems[index];
          if (item is String) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 12.0, left: 4.0),
              child: Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2563eb),
                  letterSpacing: 1.1,
                ),
              ),
            );
          } else if (item is WorkoutSession) {
            return _buildHistoryCard(context, item, workoutProvider);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    WorkoutSession session,
    WorkoutProvider provider,
  ) {
    final double volume = provider.calculateSessionVolume(session);
    
    // Format duration
    String durationText = '--';
    if (session.endTime != null) {
      final diff = session.endTime!.difference(session.startTime);
      durationText = "${diff.inMinutes} min";
    }

    final String dayFormatted = DateFormat('d MMM', 'fr_FR').format(session.startTime);
    final String timeFormatted = DateFormat('HH:mm').format(session.startTime);

    // Get exercise names as summary (using memory cache)
    final String exercisesSummary = provider.getSessionExercisesSummary(session);

    // Detect if this session broke any PRs
    final prsBroken = provider.getSessionPRs(session);
    final bool hasPRs = prsBroken.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SessionDetailScreen(session: session),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      session.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "$dayFormatted à $timeFormatted",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Summary stats row
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(durationText, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  const SizedBox(width: 16),
                  Icon(Icons.fitness_center, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text("${(volume / 1000.0).toStringAsFixed(2)} T", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  
                  if (session.averageHeartRate != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.favorite_border, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text("${session.averageHeartRate!.round()} bpm", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  ],

                  if (hasPRs) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xff2563eb).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xff2563eb), width: 0.8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("👑", style: TextStyle(fontSize: 10)),
                          SizedBox(width: 2),
                          Text(
                            "PR",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff2563eb),
                            ),
                          )
                        ],
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 12),

              // Exercises preview
              Text(
                exercisesSummary,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SessionDetailScreen extends StatelessWidget {
  final WorkoutSession session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final volume = provider.calculateSessionVolume(session);
    final prsBroken = provider.getSessionPRs(session);

    String durationText = '--';
    if (session.endTime != null) {
      final diff = session.endTime!.difference(session.startTime);
      durationText = "${diff.inMinutes} min";
    }

    final String fullDate = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(session.startTime);
    final String capitalizedDate = fullDate[0].toUpperCase() + fullDate.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de la séance"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () => _confirmDelete(context, provider),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Date
            Text(session.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
            const SizedBox(height: 4),
            Text(capitalizedDate, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            const SizedBox(height: 20),

            // Metrics Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: "Durée",
                    value: durationText,
                    icon: Icons.timer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: "Volume Total",
                    value: "${(volume / 1000.0).toStringAsFixed(2)} T",
                    icon: Icons.fitness_center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Health metrics card if available
            if (session.activeCaloriesBurned != null || session.averageHeartRate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff1e1e24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xff2d2d34)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "DONNÉES DE SANTÉ SYNC",
                      style: TextStyle(
                        color: Color(0xff2563eb),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (session.activeCaloriesBurned != null) ...[
                          const Icon(Icons.local_fire_department, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${session.activeCaloriesBurned!.round()} kcal",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text("Calories actives", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(width: 32),
                        ],
                        if (session.averageHeartRate != null) ...[
                          const Icon(Icons.favorite, color: Colors.pinkAccent, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${session.averageHeartRate!.round()} bpm",
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const Text("Fréquence Moyenne", style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // PRs Section
            if (prsBroken.isNotEmpty) ...[
              const Text("Records Personnels Battus 👑", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              ...prsBroken.map((pr) {
                final Exercise ex = pr['exercise'] as Exercise;
                final double? weightPR = pr['weightPR'] as double?;
                final double? max1RMPR = pr['oneRepMaxPR'] as double?;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  color: const Color(0xff2563eb).withValues(alpha: 0.08),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xff2563eb),
                      radius: 16,
                      child: Text("👑", style: TextStyle(fontSize: 12)),
                    ),
                    title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        if (weightPR != null)
                          Text("• Record de charge : ${weightPR.toStringAsFixed(1).replaceAll('.0', '')} kg", style: const TextStyle(fontSize: 12)),
                        if (max1RMPR != null)
                          Text("• Record 1RM estimé : ${max1RMPR.toStringAsFixed(1).replaceAll('.0', '')} kg", style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            // Exercises details List
            const Text("Exercices", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),

            ...session.exercises.map((perfEx) {
              final exercise = provider.exercises.firstWhere(
                (e) => e.id == perfEx.exerciseId,
                orElse: () => Exercise(id: perfEx.exerciseId, name: 'Exercice Supprimé', category: 'Inconnue'),
              );

              final hasGroup = perfEx.groupId != null && perfEx.groupId!.isNotEmpty;
              final groupColor = hasGroup ? _getGroupColor(perfEx.groupId!) : null;

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasGroup)
                        Container(
                          width: 5,
                          decoration: BoxDecoration(
                            color: groupColor,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (hasGroup) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: groupColor!.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: groupColor, width: 0.8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.group_work, size: 10, color: groupColor),
                                          const SizedBox(width: 4),
                                          Text(
                                            perfEx.groupId!,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                              color: groupColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              // Exercise Title
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xff2d2d34), borderRadius: BorderRadius.circular(4)),
                                    child: Text(exercise.category, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  )
                                ],
                              ),
                              if (perfEx.notes != null && perfEx.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "Notes : ${perfEx.notes}",
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                              ],
                              const Divider(),

                              // Table/List of sets
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: perfEx.sets.length,
                                itemBuilder: (context, idx) {
                                  final set = perfEx.sets[idx];
                                  
                                  // Determine type prefix
                                  String typeLabel = "${idx + 1}";
                                  if (set.type == SetType.warmup) typeLabel = "Ech.";
                                  if (set.type == SetType.dropSet) typeLabel = "Drop";
                                  if (set.type == SetType.failure) typeLabel = "Ech.";

                                  String formatDuration(int seconds) {
                                    final m = seconds ~/ 60;
                                    final s = seconds % 60;
                                    return m > 0 ? "$m:${s.toString().padLeft(2, '0')}" : "${s}s";
                                  }

                                  String metricsText = '';
                                  if (perfEx.type == ExerciseType.distance) {
                                    metricsText = "${set.distance.toStringAsFixed(1)} km en ${formatDuration(set.duration)}";
                                  } else if (perfEx.type == ExerciseType.time) {
                                    metricsText = "${set.weight.toStringAsFixed(1).replaceAll('.0', '')} lvl x ${formatDuration(set.duration)}";
                                  } else {
                                    metricsText = "${set.weight.toStringAsFixed(1).replaceAll('.0', '')} kg x ${set.reps}";
                                  }

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Série $typeLabel",
                                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              metricsText,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            if (perfEx.type == ExerciseType.reps) ...[
                                              const SizedBox(width: 8),
                                              Text(
                                                "(1RM est. ${set.estimated1RM.toStringAsFixed(1).replaceAll('.0', '')} kg)",
                                                style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                              ),
                                            ],
                                            if (set.isWeightPR || set.is1RMPR) ...[
                                              const SizedBox(width: 4),
                                              const Tooltip(
                                                message: "Record battu !",
                                                child: Text("👑", style: TextStyle(fontSize: 12)),
                                              ),
                                            ]
                                          ],
                                        )
                                      ],
                                    ),
                                  );
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xff1e1e24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xff2d2d34)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff2563eb), size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }

  Color _getGroupColor(String groupId) {
    final colors = [
      const Color(0xff2563eb), // Blue
      const Color(0xff10b981), // Green
      const Color(0xff8b5cf6), // Purple
      const Color(0xfff59e0b), // Amber/Orange
      const Color(0xffec4899), // Pink
      const Color(0xff06b6d4), // Cyan
    ];
    final hash = groupId.hashCode.abs();
    return colors[hash % colors.length];
  }

  void _confirmDelete(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la séance ?"),
        content: const Text("Êtes-vous sûr de vouloir supprimer cette séance de votre historique ? Cette action est irréversible."),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              provider.deleteSession(session.id);
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(context); // Exit Detail Screen
            },
          )
        ],
      ),
    );
  }
}
