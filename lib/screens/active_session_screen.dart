import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/performed_exercise.dart';
import '../providers/workout_provider.dart';
import '../widgets/category_badge.dart';
import '../widgets/rest_timer_overlay.dart';
import '../widgets/set_numeric_input.dart';
import '../widgets/youtube_player_dialog.dart';
import 'exercise_focus_screen.dart';
import 'workout_summary_screen.dart';

class ActiveSessionScreen extends StatelessWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final session = provider.activeSession;

    if (session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Entraînement Actif")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Aucune séance en cours"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  provider.startSession(null);
                },
                child: const Text("Démarrer une séance libre"),
              ),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ValueListenableBuilder<Duration>(
                valueListenable: provider.sessionDurationNotifier,
                builder: (context, duration, _) {
                  final String durationString = '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
                  return Text(
                    "Durée : $durationString",
                    style: const TextStyle(fontSize: 12, color: Color(0xff2563eb), fontWeight: FontWeight.w500),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _showCancelConfirm(context, provider),
              child: const Text("Annuler", style: TextStyle(color: Colors.redAccent)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _finishSession(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text("Terminer", style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: Column(
          children: [
            if (session.exercises.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xff2563eb).withValues(alpha: 0.2),
                      const Color(0xff1d4ed8).withValues(alpha: 0.05),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xff2563eb).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.center_focus_strong, color: Color(0xff60a5fa), size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Mode Focus Exercice", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text("Exercice par exercice avec swipe & navigation", style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        int firstIncomplete = session.exercises.indexWhere((e) => e.sets.any((s) => !s.isCompleted));
                        if (firstIncomplete == -1) firstIncomplete = 0;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExerciseFocusScreen(initialIndex: firstIncomplete),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563eb),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text("Aller à l'exercice", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Exercise List
            Expanded(
              child: session.exercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center_outlined, size: 48, color: Colors.grey[600]),
                          const SizedBox(height: 16),
                          const Text("Aucun exercice dans cette séance", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _showAddExerciseSheet(context, provider),
                            child: const Text("Ajouter un exercice"),
                          )
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                      itemCount: session.exercises.length,
                      // ignore: deprecated_member_use
                      onReorder: provider.reorderExercisesInActiveSession,
                      itemBuilder: (context, index) {
                        final perfEx = session.exercises[index];
                        final exercise = provider.exercises.firstWhere(
                          (e) => e.id == perfEx.exerciseId,
                          orElse: () => Exercise(id: perfEx.exerciseId, name: "Exercice Supprimé", category: "Inconnue"),
                        );
                        return _buildExerciseCard(context, perfEx, exercise, provider, index);
                      },
                    ),
            ),
          ],
        ),
        // Rest Timer overlay at the bottom
        bottomSheet: provider.isRestTimerActive ? const RestTimerOverlay() : null,
        floatingActionButton: !provider.isRestTimerActive && session.exercises.isNotEmpty
            ? FloatingActionButton.extended(
                backgroundColor: const Color(0xff2563eb),
                onPressed: () => _showAddExerciseSheet(context, provider),
                icon: const Icon(Icons.add),
                label: const Text("Exercice"),
              )
            : null,
      ),
    );
  }

  Widget _buildExerciseCard(
    BuildContext context,
    PerformedExercise perfEx,
    Exercise exercise,
    WorkoutProvider provider,
    int index,
  ) {
    final hasGroup = perfEx.groupId != null && perfEx.groupId!.isNotEmpty;
    final groupColor = hasGroup ? _getGroupColor(perfEx.groupId!) : null;

    return Card(
      key: ValueKey(perfEx.exerciseId),
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
                    // Exercise Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              MultiCategoryBadges(categories: exercise.categories, compact: true),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.center_focus_strong, color: Color(0xff60a5fa), size: 24),
                          tooltip: "Mode Focus (Aller à cet exercice)",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExerciseFocusScreen(initialIndex: index),
                              ),
                            );
                          },
                        ),
                        if (exercise.videoUrl != null && exercise.videoUrl!.trim().isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 28),
                            tooltip: "Vidéo d'explication",
                            onPressed: () => YoutubePlayerDialog.show(context, exercise.name, exercise.videoUrl!),
                          ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) {
                            if (value == 'focus') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ExerciseFocusScreen(initialIndex: index),
                                ),
                              );
                            } else if (value == 'delete') {
                              provider.removeExerciseFromActiveSession(perfEx.exerciseId);
                            } else if (value == 'notes') {
                              _showNotesDialog(context, perfEx, provider);
                            } else if (value == 'group') {
                              _showGroupDialog(context, perfEx, provider);
                            } else if (value == 'type') {
                              _showChangeTypeDialog(context, perfEx, provider);
                            } else if (value == 'video' && exercise.videoUrl != null) {
                              YoutubePlayerDialog.show(context, exercise.name, exercise.videoUrl!);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'focus',
                              child: Row(
                                children: [
                                  Icon(Icons.center_focus_strong, color: Color(0xff60a5fa), size: 20),
                                  SizedBox(width: 8),
                                  Text("Aller à cet exercice (Focus)"),
                                ],
                              ),
                            ),
                            if (exercise.videoUrl != null && exercise.videoUrl!.trim().isNotEmpty)
                              const PopupMenuItem(
                                value: 'video',
                                child: Row(
                                  children: [
                                    Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text("Vidéo d'explication"),
                                  ],
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'notes',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_note, size: 20),
                                  SizedBox(width: 8),
                                  Text("Notes d'exercice"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'group',
                              child: Row(
                                children: [
                                  Icon(Icons.group_work, size: 20),
                                  SizedBox(width: 8),
                                  Text("Associer à un groupe"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'type',
                              child: Row(
                                children: [
                                  Icon(Icons.fitness_center, size: 20),
                                  SizedBox(width: 8),
                                  Text("Type d'évaluation"),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                  SizedBox(width: 8),
                                  Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (perfEx.notes != null && perfEx.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          perfEx.notes!,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Sets Header
                    Row(
                      children: [
                        SizedBox(
                          width: 45,
                          child: Text(
                            perfEx.type.headers[0],
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                perfEx.type.headers[1],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                perfEx.type.headers[2],
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(
                          width: 45,
                          child: Center(
                            child: Text(
                              perfEx.type.headers[3],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Sets List
                    ...perfEx.sets.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final set = entry.value;
                      return _buildSetRow(context, perfEx, exercise, set, idx, provider);
                    }),


                    const SizedBox(height: 8),
                    // Add Set Button
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xff2d2d34)),
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("Ajouter une série", style: TextStyle(fontSize: 12)),
                            onPressed: () {
                              provider.addSetToPerformedExercise(perfEx);
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(
    BuildContext context,
    PerformedExercise perfEx,
    Exercise exercise,
    ExerciseSet set,
    int index,
    WorkoutProvider provider,
  ) {

    final bool isCompleted = set.isCompleted;

    // Determine background color based on completion state
    final Color rowBg = isCompleted ? const Color(0xff142f23) : Colors.transparent;

    // Get letter representation of set type
    String setLetter = (index + 1).toString();
    Color setLetterColor = Colors.white70;
    if (set.type == SetType.warmup) {
      setLetter = "E"; // Échauffement
      setLetterColor = Colors.amber;
    } else if (set.type == SetType.dropSet) {
      setLetter = "D"; // Drop set
      setLetterColor = Colors.purpleAccent;
    } else if (set.type == SetType.failure) {
      setLetter = "Ech"; // Échec
      setLetterColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set Type Selector (tapping opens a menu)
          GestureDetector(
            onTap: () => _showSetTypeMenu(context, set, provider),
            child: SizedBox(
              width: 45,
              child: Center(
                child: CircleAvatar(
                  radius: 13,
                  backgroundColor: isCompleted ? const Color(0xff10b981).withValues(alpha: 0.2) : const Color(0xff2d2d34),
                  child: Text(
                    setLetter,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? const Color(0xff10b981) : setLetterColor,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Switch variables based on exercise type
          Expanded(
            flex: 3,
            child: _buildSetCol1(context, perfEx, exercise, set, isCompleted, provider),
          ),

          Expanded(
            flex: 3,
            child: _buildSetCol2(context, perfEx, exercise, set, isCompleted, provider),
          ),


          // Check OK / PR Indicator
          SizedBox(
            width: 45,
            child: Center(
              child: InkWell(
                onTap: () {
                  provider.toggleSetCompletion(perfEx, set);
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xff10b981) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCompleted ? const Color(0xff10b981) : const Color(0xff2d2d34),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),

          // Small float-in PR indicators
          if (isCompleted && (set.isWeightPR || set.is1RMPR)) ...[
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Tooltip(
                message: set.isWeightPR && set.is1RMPR
                    ? "PR de poids & volume !"
                    : (set.isWeightPR ? "PR de charge maximale !" : "PR de volume (1RM) !"),
                child: const Text("👑", style: TextStyle(fontSize: 13)),
              ),
            ),
          ]
        ],
      ),
    );
  }

  void _showSetTypeMenu(BuildContext context, ExerciseSet set, WorkoutProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xff1e1e24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Type de Série", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(radius: 12, child: Text("N", style: TextStyle(fontSize: 11))),
                title: const Text("Normale"),
                trailing: set.type == SetType.normal ? const Icon(Icons.check, color: Color(0xff2563eb)) : null,
                onTap: () {
                  provider.updateSetType(set, SetType.normal);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const CircleAvatar(radius: 12, backgroundColor: Colors.amber, child: Text("E", style: TextStyle(fontSize: 11, color: Colors.black))),
                title: const Text("Échauffement (Warmup)"),
                trailing: set.type == SetType.warmup ? const Icon(Icons.check, color: Color(0xff2563eb)) : null,
                onTap: () {
                  provider.updateSetType(set, SetType.warmup);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const CircleAvatar(radius: 12, backgroundColor: Colors.purpleAccent, child: Text("D", style: TextStyle(fontSize: 11))),
                title: const Text("Drop Set"),
                trailing: set.type == SetType.dropSet ? const Icon(Icons.check, color: Color(0xff2563eb)) : null,
                onTap: () {
                  provider.updateSetType(set, SetType.dropSet);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const CircleAvatar(radius: 12, backgroundColor: Colors.redAccent, child: Text("F", style: TextStyle(fontSize: 11))),
                title: const Text("Jusqu'à l'échec (Failure)"),
                trailing: set.type == SetType.failure ? const Icon(Icons.check, color: Color(0xff2563eb)) : null,
                onTap: () {
                  provider.updateSetType(set, SetType.failure);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSetCol1(
    BuildContext context,
    PerformedExercise perfEx,
    Exercise exercise,
    ExerciseSet set,
    bool isCompleted,
    WorkoutProvider provider,
  ) {
    switch (perfEx.type) {
      case ExerciseType.reps:
      case ExerciseType.isometry:
      case ExerciseType.tempo:
      case ExerciseType.circuit:
        return SetNumericInput(
          initialValue: set.weight,
          suffix: "kg",
          isDecimal: true,
          enabled: !isCompleted,
          onChanged: (val) {
            provider.updateSetMetrics(set, val, set.reps);
          },
        );

      case ExerciseType.cardio:
        return SetNumericInput(
          initialValue: set.distance,
          suffix: "km",
          isDecimal: true,
          enabled: !isCompleted,
          onChanged: (val) {
            provider.updateSetMetrics(set, set.weight, set.reps, distance: val);
          },
        );

      case ExerciseType.intervals:
        return SetNumericInput(
          initialValue: (set.workTime > 0 ? set.workTime : 30).toDouble(),
          suffix: "s eff",
          isDecimal: false,
          enabled: !isCompleted,
          onChanged: (val) {
            set.workTime = val.toInt();
            provider.updateSetMetrics(set, set.weight, set.reps);
          },
        );

      case ExerciseType.amrap:
      case ExerciseType.forTime:
        return SetNumericInput(
          initialValue: set.reps.toDouble(),
          suffix: "reps",
          isDecimal: false,
          enabled: !isCompleted,
          onChanged: (val) {
            provider.updateSetMetrics(set, set.weight, val.toInt());
          },
        );

      case ExerciseType.emom:
        return Center(
          child: Text(
            "${set.reps} cibles",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[400]),
          ),
        );

      case ExerciseType.video:
        return Center(
          child: Text(
            "${set.duration ~/ 60 > 0 ? set.duration ~/ 60 : 20} min",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
    }
  }

  Widget _buildSetCol2(
    BuildContext context,
    PerformedExercise perfEx,
    Exercise exercise,
    ExerciseSet set,
    bool isCompleted,
    WorkoutProvider provider,
  ) {
    switch (perfEx.type) {
      case ExerciseType.reps:
      case ExerciseType.circuit:
      case ExerciseType.emom:
      case ExerciseType.tempo:
        return SetNumericInput(
          initialValue: set.reps.toDouble(),
          suffix: "",
          isDecimal: false,
          enabled: !isCompleted,
          onChanged: (val) {
            provider.updateSetMetrics(set, set.weight, val.toInt());
          },
        );

      case ExerciseType.isometry:
      case ExerciseType.cardio:
      case ExerciseType.forTime:
        return SetNumericInput(
          initialValue: set.duration.toDouble(),
          suffix: "s",
          isDecimal: false,
          enabled: !isCompleted,
          onChanged: (val) {
            provider.updateSetMetrics(set, set.weight, set.reps, duration: val.toInt());
          },
        );

      case ExerciseType.intervals:
        return SetNumericInput(
          initialValue: (set.intervalRest > 0 ? set.intervalRest : 15).toDouble(),
          suffix: "s rep",
          isDecimal: false,
          enabled: !isCompleted,
          onChanged: (val) {
            set.intervalRest = val.toInt();
            provider.updateSetMetrics(set, set.weight, set.reps);
          },
        );

      case ExerciseType.amrap:
        return SetNumericInput(
          initialValue: set.duration.toDouble(),
          suffix: "s",
          isDecimal: false,
          enabled: !isCompleted,
          onChanged: (val) {
            provider.updateSetMetrics(set, set.weight, set.reps, duration: val.toInt());
          },
        );

      case ExerciseType.video:
        final String? url = exercise.videoUrl;
        return Center(
          child: InkWell(
            onTap: () {
              if (url != null && url.isNotEmpty) {
                YoutubePlayerDialog.show(context, exercise.name, url);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aucune URL vidéo associée")),
                );
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
                SizedBox(width: 4),
                Text("Vidéo", style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
    }
  }


  void _showAddExerciseSheet(BuildContext context, WorkoutProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff121214),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filtered = provider.exercises.where((e) {
              return e.name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.8,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text("Ajouter un exercice", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: "Rechercher...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          setStateSheet(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final ex = filtered[index];
                          final isAdded = provider.activeSession?.exercises.any((pe) => pe.exerciseId == ex.id) ?? false;

                          return ListTile(
                            title: Text(ex.name),
                            subtitle: Text(ex.category),
                            trailing: isAdded
                                ? const Icon(Icons.check_circle, color: Color(0xff2563eb))
                                : const Icon(Icons.add_circle_outline),
                            onTap: () {
                              if (!isAdded) {
                                provider.addExerciseToActiveSession(ex);
                              } else {
                                provider.removeExerciseFromActiveSession(ex.id);
                              }
                              setStateSheet(() {}); // trigger rebuild inside sheet
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showNotesDialog(BuildContext context, PerformedExercise perfEx, WorkoutProvider provider) {
    final controller = TextEditingController(text: perfEx.notes);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Notes d'exercice"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Ex : Concentrer sur le tempo, 3s descente...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Enregistrer"),
            onPressed: () {
              provider.updatePerformedExerciseNotes(perfEx, controller.text.trim());
              Navigator.pop(ctx);
            },
          )
        ],
      ),
    );
  }

  void _showCancelConfirm(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Annuler la séance ?"),
        content: const Text("Toutes les séries complétées et modifications seront perdues."),
        actions: [
          TextButton(
            child: const Text("Continuer la séance"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Annuler la séance", style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              provider.cancelActiveSession();
              Navigator.pop(ctx); // Close Dialog
              Navigator.pop(context); // Exit ActiveSessionScreen
            },
          )
        ],
      ),
    );
  }

  void _finishSession(BuildContext context, WorkoutProvider provider) async {
    final session = provider.activeSession;
    if (session == null) return;

    // Check if there are completed sets
    final hasCompletedSets = session.exercises.any((e) => e.sets.any((s) => s.isCompleted));

    if (!hasCompletedSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous devez compléter au moins une série pour enregistrer la séance.")),
      );
      return;
    }

    // Show processing loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Enregistrement de la séance & synchro Santé..."),
              ],
            ),
          ),
        ),
      ),
    );

    // Save session
    final completedSession = await provider.finishActiveSession();

    if (!context.mounted) return;

    // Close loader
    Navigator.pop(context); // pop loader

    if (completedSession != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WorkoutSummaryScreen(
            session: completedSession,
            isNewCompletion: true,
          ),
        ),
      );
    } else {
      Navigator.pop(context); // pop active session screen
    }
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

  void _showGroupDialog(BuildContext context, PerformedExercise perfEx, WorkoutProvider provider) {
    final session = provider.activeSession;
    if (session == null) return;

    final existingGroups = session.exercises
        .map((e) => e.groupId)
        .where((g) => g != null && g.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        String? newGroupName;
        return AlertDialog(
          title: const Text("Associer à un groupe"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (existingGroups.isNotEmpty) ...[
                  const Text("Groupes existants :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...existingGroups.map((group) {
                    final isCurrent = perfEx.groupId == group;
                    return ListTile(
                      title: Text(group),
                      leading: Icon(Icons.group_work, color: _getGroupColor(group)),
                      trailing: isCurrent ? const Icon(Icons.check, color: Color(0xff2563eb)) : null,
                      onTap: () {
                        provider.setExerciseGroup(perfEx, group);
                        Navigator.pop(context);
                      },
                    );
                  }),
                  const Divider(),
                ],
                const Text("Nouveau groupe :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: "Nom du groupe (ex: Superset A)",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    newGroupName = val.trim();
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (perfEx.groupId != null && perfEx.groupId!.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          provider.setExerciseGroup(perfEx, null);
                          Navigator.pop(context);
                        },
                        child: const Text("Retirer du groupe", style: TextStyle(color: Colors.redAccent)),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: () {
                        if (newGroupName != null && newGroupName!.isNotEmpty) {
                          provider.setExerciseGroup(perfEx, newGroupName);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text("Créer"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showChangeTypeDialog(BuildContext context, PerformedExercise perfEx, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Type d'évaluation"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ExerciseType.values.map((t) {
              return ListTile(
                title: Text(t.label),
                trailing: perfEx.type == t ? const Icon(Icons.check, color: Color(0xff2563eb)) : null,
                onTap: () {
                  provider.updateActiveSessionExerciseType(perfEx.exerciseId, t);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
