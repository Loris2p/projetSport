import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/exercise_set.dart';
import '../models/performed_exercise.dart';
import '../providers/workout_provider.dart';
import '../widgets/category_badge.dart';
import '../widgets/set_numeric_input.dart';
import '../widgets/youtube_player_dialog.dart';
import 'workout_summary_screen.dart';

class ExerciseFocusScreen extends StatefulWidget {
  final int initialIndex;

  const ExerciseFocusScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<ExerciseFocusScreen> createState() => _ExerciseFocusScreenState();
}

class _ExerciseFocusScreenState extends State<ExerciseFocusScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WorkoutProvider>(context);
    final session = provider.activeSession;

    if (session == null || session.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mode Focus")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Aucun exercice dans la séance"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Retour au programme"),
              ),
            ],
          ),
        ),
      );
    }

    // Clamp current index within bounds if an exercise was deleted
    if (_currentIndex >= session.exercises.length) {
      _currentIndex = session.exercises.length - 1;
    }

    final totalExercises = session.exercises.length;

    final completedExercisesCount = session.exercises
        .where((e) => e.sets.isNotEmpty && e.sets.every((s) => s.isCompleted))
        .length;
    final double progressValue = totalExercises > 0 ? (completedExercisesCount / totalExercises) : 0.0;
    final int progressPercentage = (progressValue * 100).round();

    final currentPerfEx = (_currentIndex >= 0 && _currentIndex < session.exercises.length)
        ? session.exercises[_currentIndex]
        : null;
    final bool isCurrentCompleted = currentPerfEx != null &&
        currentPerfEx.sets.isNotEmpty &&
        currentPerfEx.sets.every((s) => s.isCompleted);

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.format_list_bulleted, size: 24),
            tooltip: "Vue Liste Complète",
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.name,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              ValueListenableBuilder<Duration>(
                valueListenable: provider.sessionDurationNotifier,
                builder: (context, duration, _) {
                  final String durationString =
                      '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
                  return Text(
                    "Durée : $durationString",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xff2563eb),
                      fontWeight: FontWeight.w500,
                    ),
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
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: () => _finishSession(context, provider),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text("Terminer", style: TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Progress header bar based on COMPLETED exercises
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xff18181c),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCurrentCompleted
                              ? const Color(0xff10b981).withValues(alpha: 0.2)
                              : const Color(0xff2563eb).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCurrentCompleted
                                ? const Color(0xff10b981).withValues(alpha: 0.5)
                                : const Color(0xff2563eb).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Exercice ${_currentIndex + 1} sur $totalExercises",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCurrentCompleted ? const Color(0xff34d399) : const Color(0xff60a5fa),
                              ),
                            ),
                            if (isCurrentCompleted) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.check_circle, size: 14, color: Color(0xff10b981)),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        "$completedExercisesCount / $totalExercises complétés ($progressPercentage%)",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressValue,
                      minHeight: 6,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressValue == 1.0 ? const Color(0xff10b981) : const Color(0xff2563eb),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // PageView for exercises
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalExercises,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final perfEx = session.exercises[index];
                  final exercise = provider.exercises.firstWhere(
                    (e) => e.id == perfEx.exerciseId,
                    orElse: () => Exercise(
                      id: perfEx.exerciseId,
                      name: "Exercice Supprimé",
                      category: "Inconnue",
                    ),
                  );
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildFocusedExerciseCard(context, perfEx, exercise, provider, index),
                  );
                },
              ),
            ),
          ],
        ),

        // Rest Timer banner if active
        bottomSheet: provider.isRestTimerActive ? _buildRestTimerSheet(context, provider) : null,

        // Bottom Navigation bar with Previous / List / Next buttons
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xff18181c),
              border: Border(top: BorderSide(color: Color(0xff2d2d34))),
            ),
            child: Row(
              children: [
                // Previous Exercise Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _currentIndex > 0
                        ? () => _navigateToPage(_currentIndex - 1)
                        : null,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text("Précédent", style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Return to List View Button
                IconButton(
                  tooltip: "Vue Liste Complète",
                  icon: const Icon(Icons.format_list_bulleted, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xff2d2d34)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Next Exercise or Finish Button
                Expanded(
                  child: _currentIndex < totalExercises - 1
                      ? ElevatedButton.icon(
                          onPressed: () => _navigateToPage(_currentIndex + 1),
                          icon: const Text("Suivant", style: TextStyle(fontSize: 12)),
                          label: const Icon(Icons.arrow_forward, size: 16),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2563eb),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _finishSession(context, provider),
                          icon: const Icon(Icons.check_circle, size: 16),
                          label: const Text("Terminer", style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff10b981),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusedExerciseCard(
    BuildContext context,
    PerformedExercise perfEx,
    Exercise exercise,
    WorkoutProvider provider,
    int index,
  ) {
    final hasGroup = perfEx.groupId != null && perfEx.groupId!.isNotEmpty;
    final groupColor = hasGroup ? _getGroupColor(perfEx.groupId!) : null;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group badge if superset/circuit
            if (hasGroup) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: groupColor!.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: groupColor, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_work, size: 14, color: groupColor),
                    const SizedBox(width: 6),
                    Text(
                      perfEx.groupId!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: groupColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Exercise Title and Actions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      MultiCategoryBadges(categories: exercise.categories),
                    ],
                  ),
                ),
                if (exercise.videoUrl != null && exercise.videoUrl!.trim().isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 32),
                    tooltip: "Vidéo d'explication",
                    onPressed: () => YoutubePlayerDialog.show(context, exercise.name, exercise.videoUrl!),
                  ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) {
                    if (value == 'delete') {
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

            // Exercise Notes if any
            if (perfEx.notes != null && perfEx.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        perfEx.notes!,
                        style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Sets Header
            Row(
              children: [
                SizedBox(
                  width: 45,
                  child: Text(
                    perfEx.type.headers[0],
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      perfEx.type.headers[1],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      perfEx.type.headers[2],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(
                  width: 45,
                  child: Center(
                    child: Text(
                      perfEx.type.headers[3],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Sets List
            ...perfEx.sets.asMap().entries.map((entry) {
              final idx = entry.key;
              final set = entry.value;
              return _buildSetRow(context, perfEx, set, idx, provider);
            }),

            const SizedBox(height: 12),
            // Add Set Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: const BorderSide(color: Color(0xff2d2d34)),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Ajouter une série", style: TextStyle(fontSize: 13)),
              onPressed: () {
                provider.addSetToPerformedExercise(perfEx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(
    BuildContext context,
    PerformedExercise perfEx,
    ExerciseSet set,
    int index,
    WorkoutProvider provider,
  ) {
    final bool isCompleted = set.isCompleted;

    final Color rowBg = isCompleted ? const Color(0xff142f23) : Colors.transparent;

    String setLetter = (index + 1).toString();
    Color setLetterColor = Colors.white70;
    if (set.type == SetType.warmup) {
      setLetter = "E";
      setLetterColor = Colors.amber;
    } else if (set.type == SetType.dropSet) {
      setLetter = "D";
      setLetterColor = Colors.purpleAccent;
    } else if (set.type == SetType.failure) {
      setLetter = "Ech";
      setLetterColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      decoration: BoxDecoration(
        color: rowBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Set Type Selector
          GestureDetector(
            onTap: () => _showSetTypeMenu(context, set, provider),
            child: SizedBox(
              width: 45,
              child: Center(
                child: CircleAvatar(
                  radius: 14,
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

          // Weight/Resistance/Distance Column
          Expanded(
            flex: 3,
            child: perfEx.type == ExerciseType.distance
                ? SetNumericInput(
                    initialValue: set.distance,
                    suffix: "km",
                    isDecimal: true,
                    enabled: !isCompleted,
                    onChanged: (val) {
                      provider.updateSetMetrics(set, set.weight, set.reps, distance: val);
                    },
                  )
                : SetNumericInput(
                    initialValue: set.weight,
                    suffix: perfEx.type == ExerciseType.time ? "lvl" : "kg",
                    isDecimal: true,
                    enabled: !isCompleted,
                    onChanged: (val) {
                      provider.updateSetMetrics(set, val, set.reps);
                    },
                  ),
          ),

          // Reps/Duration Column
          Expanded(
            flex: 3,
            child: perfEx.type == ExerciseType.reps
                ? SetNumericInput(
                    initialValue: set.reps.toDouble(),
                    suffix: "",
                    isDecimal: false,
                    enabled: !isCompleted,
                    onChanged: (val) {
                      provider.updateSetMetrics(set, set.weight, val.toInt());
                    },
                  )
                : SetNumericInput(
                    initialValue: set.duration.toDouble(),
                    suffix: "s",
                    isDecimal: false,
                    enabled: !isCompleted,
                    onChanged: (val) {
                      provider.updateSetMetrics(set, set.weight, set.reps, duration: val.toInt());
                    },
                  ),
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted ? const Color(0xff10b981) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCompleted ? const Color(0xff10b981) : const Color(0xff2d2d34),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ),
            ),
          ),

          if (isCompleted && (set.isWeightPR || set.is1RMPR)) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
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

  Widget _buildRestTimerSheet(BuildContext context, WorkoutProvider provider) {
    final total = provider.restTimerDuration;

    return ValueListenableBuilder<int>(
      valueListenable: provider.restTimerRemainingNotifier,
      builder: (context, remaining, _) {
        final progress = total > 0 ? remaining / total : 0.0;
        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xff1e1e24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xff2563eb), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Temps de repos", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(
                          "${(remaining ~/ 60)}:${(remaining % 60).toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff2563eb),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: const Color(0xff2d2d34),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xff2563eb)),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  provider.startRestTimer(remaining + 15);
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, size: 20, color: Colors.grey),
                onPressed: () {
                  provider.stopRestTimer();
                },
              ),
            ],
          ),
        );
      },
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

  Color _getGroupColor(String groupId) {
    final colors = [
      const Color(0xff2563eb),
      const Color(0xff10b981),
      const Color(0xff8b5cf6),
      const Color(0xfff59e0b),
      const Color(0xffec4899),
      const Color(0xff06b6d4),
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
              Navigator.pop(context); // Exit ExerciseFocusScreen
            },
          )
        ],
      ),
    );
  }

  void _finishSession(BuildContext context, WorkoutProvider provider) async {
    final session = provider.activeSession;
    if (session == null) return;

    final hasCompletedSets = session.exercises.any((e) => e.sets.any((s) => s.isCompleted));

    if (!hasCompletedSets) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vous devez compléter au moins une série pour enregistrer la séance.")),
      );
      return;
    }

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

    final completedSession = await provider.finishActiveSession();

    if (!context.mounted) return;

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
      Navigator.pop(context);
    }
  }
}
