import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/workout_session.dart';
import '../providers/workout_provider.dart';

class WorkoutSummaryScreen extends StatefulWidget {
  final WorkoutSession session;
  final bool isNewCompletion;

  const WorkoutSummaryScreen({
    super.key,
    required this.session,
    this.isNewCompletion = false,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late int _rating;
  late TextEditingController _notesController;
  bool _isSavingNotes = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.session.rating ?? 0;
    _notesController = TextEditingController(text: widget.session.notes ?? '');
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotesAndRating(WorkoutProvider provider) async {
    setState(() {
      _isSavingNotes = true;
    });

    final updatedSession = WorkoutSession(
      id: widget.session.id,
      programId: widget.session.programId,
      name: widget.session.name,
      startTime: widget.session.startTime,
      endTime: widget.session.endTime,
      exercises: widget.session.exercises,
      activeCaloriesBurned: widget.session.activeCaloriesBurned,
      averageHeartRate: widget.session.averageHeartRate,
      rating: _rating > 0 ? _rating : null,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    await provider.updateSession(updatedSession);

    if (mounted) {
      setState(() {
        _isSavingNotes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bilan mis à jour avec succès !"),
          backgroundColor: Color(0xff10b981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final volume = provider.calculateSessionVolume(widget.session);
    final prsBroken = provider.getSessionPRs(widget.session);

    // Calculate duration
    String durationText = '--';
    if (widget.session.endTime != null) {
      final diff = widget.session.endTime!.difference(widget.session.startTime);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      if (minutes > 60) {
        final hours = minutes ~/ 60;
        final remainingMin = minutes % 60;
        durationText = "${hours}h ${remainingMin}m";
      } else {
        durationText = "${minutes}m ${seconds}s";
      }
    }

    // Total completed sets count
    int totalCompletedSets = 0;
    for (var ex in widget.session.exercises) {
      totalCompletedSets += ex.sets.where((s) => s.isCompleted).length;
    }

    // Format date
    final String fullDate = DateFormat('EEEE d MMMM yyyy à HH:mm', 'fr_FR').format(widget.session.startTime);
    final String capitalizedDate = fullDate[0].toUpperCase() + fullDate.substring(1);

    // Program name if available
    String? programName;
    if (widget.session.programId != null) {
      final prog = provider.programs.where((p) => p.id == widget.session.programId).firstOrNull;
      if (prog != null) {
        programName = prog.name;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xff0b0f19),
      appBar: AppBar(
        backgroundColor: const Color(0xff0b0f19),
        elevation: 0,
        title: Text(
          widget.isNewCompletion ? "Bilan de la séance" : "Détails de la séance",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xffef4444)),
            tooltip: "Supprimer la séance",
            onPressed: () => _confirmDelete(context, provider),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Celebration Banner (if newly completed)
            if (widget.isNewCompletion) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff2563eb), Color(0xff7c3aed)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff7c3aed).withValues(alpha: 0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text("🏆", style: TextStyle(fontSize: 30)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Séance terminée ! 🔥",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            programName != null
                                ? "Étape validée dans le programme $programName !"
                                : "Excellent travail ! Félicitations pour vos efforts.",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Session Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xff3b82f6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xff3b82f6).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          programName != null ? "PROGRAMME" : "SÉANCE LIBRE",
                          style: const TextStyle(
                            color: Color(0xff60a5fa),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      if (programName != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            programName,
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.session.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white60),
                      const SizedBox(width: 6),
                      Text(
                        capitalizedDate,
                        style: const TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Key Metrics 2x2 Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  title: "DURÉE",
                  value: durationText,
                  icon: Icons.timer_outlined,
                  color: const Color(0xff3b82f6),
                ),
                _buildStatCard(
                  title: "VOLUME TOTAL",
                  value: volume >= 1000
                      ? "${(volume / 1000.0).toStringAsFixed(2)} T"
                      : "${volume.toStringAsFixed(0)} kg",
                  icon: Icons.fitness_center_outlined,
                  color: const Color(0xff10b981),
                ),
                _buildStatCard(
                  title: "SÉRIES VALIDÉES",
                  value: "$totalCompletedSets",
                  subtitle: "sur ${widget.session.exercises.fold<int>(0, (sum, e) => sum + e.sets.length)} au total",
                  icon: Icons.check_circle_outline,
                  color: const Color(0xff8b5cf6),
                ),
                _buildStatCard(
                  title: "EXERCICES",
                  value: "${widget.session.exercises.length}",
                  icon: Icons.format_list_bulleted,
                  color: const Color(0xfff59e0b),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Health Metrics Card (if synced)
            if (widget.session.activeCaloriesBurned != null || widget.session.averageHeartRate != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    if (widget.session.activeCaloriesBurned != null) ...[
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xffef4444).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.local_fire_department, color: Color(0xfff87171), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${widget.session.activeCaloriesBurned!.round()} kcal",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                const Text("Calories actives", style: TextStyle(fontSize: 12, color: Colors.white60)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (widget.session.averageHeartRate != null) ...[
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xffec4899).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.favorite_rounded, color: Color(0xfff472b6), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${widget.session.averageHeartRate!.round()} bpm",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                ),
                                const Text("Fréquence moy.", style: TextStyle(fontSize: 12, color: Colors.white60)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // PR Section (if broken)
            if (prsBroken.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xfff59e0b).withValues(alpha: 0.15),
                      const Color(0xffd97706).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xfff59e0b).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Text("👑", style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text(
                          "RECORDS PERSONNELS BATTUS !",
                          style: TextStyle(
                            color: Color(0xfffbbf24),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...prsBroken.map((pr) {
                      final Exercise ex = pr['exercise'] as Exercise;
                      final double? weightPR = pr['weightPR'] as double?;
                      final double? max1RMPR = pr['oneRepMaxPR'] as double?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (weightPR != null)
                                    Text(
                                      "• Charge max : ${weightPR.toStringAsFixed(1).replaceAll('.0', '')} kg",
                                      style: const TextStyle(color: Color(0xfffbbf24), fontSize: 12),
                                    ),
                                  if (max1RMPR != null)
                                    Text(
                                      "• 1RM estimé : ${max1RMPR.toStringAsFixed(1).replaceAll('.0', '')} kg",
                                      style: const TextStyle(color: Color(0xfffbbf24), fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xfff59e0b),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                "PR",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
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
            ],

            // Feeling & Notes Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RESSENTI & NOTES",
                    style: TextStyle(
                      color: Color(0xff94a3b8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 5 Star rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        iconSize: 32,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: starValue <= _rating ? const Color(0xfff59e0b) : Colors.white30,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = starValue;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Notes Text Field
                  TextField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Ajoutez vos notes sur la séance (forme, énergie, sensations...)",
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.04),
                      contentPadding: const EdgeInsets.all(14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xff3b82f6), width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Save notes button
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563eb),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _isSavingNotes ? null : () => _saveNotesAndRating(provider),
                      icon: _isSavingNotes
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 18),
                      label: const Text("Sauvegarder", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Exercises Summary List Header
            const Text(
              "EXERCICES EFFECTUÉS",
              style: TextStyle(
                color: Color(0xff94a3b8),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            // Exercises Details List
            ...widget.session.exercises.map((perfEx) {
              final Exercise? exercise = provider.exercises
                  .where((e) => e.id == perfEx.exerciseId)
                  .firstOrNull;

              final String exerciseName = exercise?.name ?? "Exercice incalculé";
              final String categoryName = exercise?.category ?? "";

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xff2563eb).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.fitness_center, color: Color(0xff60a5fa), size: 20),
                    ),
                    title: Text(
                      exerciseName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    ),
                    subtitle: categoryName.isNotEmpty
                        ? Text(categoryName, style: const TextStyle(color: Colors.white54, fontSize: 12))
                        : null,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 8),

                            // Sets table headers
                            const Row(
                              children: [
                                SizedBox(width: 40, child: Text("Série", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                                Expanded(child: Text("Charge / Temps", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                                SizedBox(width: 60, child: Text("Rép / Dist", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                                SizedBox(width: 40, child: Text("Status", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Sets list
                            ...perfEx.sets.asMap().entries.map((entry) {
                              final int idx = entry.key + 1;
                              final ExerciseSet set = entry.value;

                              String weightText = "${set.weight.toStringAsFixed(1).replaceAll('.0', '')} kg";
                              if (set.duration > 0) {
                                weightText = "${set.duration}s";
                              }

                              String repsText = "${set.reps}";
                              if (set.distance > 0) {
                                repsText = "${set.distance.toStringAsFixed(1)} km";
                              }

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 40,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getSetTypeColor(set.type).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "$idx",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _getSetTypeColor(set.type),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(weightText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                          if (set.isWeightPR || set.is1RMPR) ...[
                                            const SizedBox(width: 6),
                                            const Text("👑", style: TextStyle(fontSize: 12)),
                                          ],
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      width: 60,
                                      child: Text(repsText, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Icon(
                                        set.isCompleted ? Icons.check_circle : Icons.cancel_outlined,
                                        size: 18,
                                        color: set.isCompleted ? const Color(0xff10b981) : Colors.white30,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            if (perfEx.notes != null && perfEx.notes!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Note : ${perfEx.notes}",
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Bottom Finish Button
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xff2563eb), Color(0xff7c3aed)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff2563eb).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  widget.isNewCompletion ? "Retour au Tableau de bord" : "Fermer",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.white54),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Color _getSetTypeColor(SetType type) {
    switch (type) {
      case SetType.warmup:
        return const Color(0xfff59e0b);
      case SetType.dropSet:
        return const Color(0xffec4899);
      case SetType.failure:
        return const Color(0xffef4444);
      case SetType.normal:
        return const Color(0xff3b82f6);
    }
  }

  void _confirmDelete(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xff1e293b),
        title: const Text("Supprimer la séance ?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Êtes-vous sûr de vouloir supprimer cette séance de votre historique ? Cette action est irréversible.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Annuler", style: TextStyle(color: Colors.white60)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xffef4444)),
            child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              await provider.deleteSession(widget.session.id);
              if (context.mounted) {
                Navigator.pop(context); // Close summary screen
              }
            },
          ),
        ],
      ),
    );
  }
}
