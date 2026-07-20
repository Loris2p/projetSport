import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/program_exercise.dart';
import '../providers/workout_provider.dart';
import '../widgets/category_badge.dart';
import '../widgets/youtube_player_dialog.dart';
import 'active_session_screen.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final programs = workoutProvider.programs;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Programmes"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xff2563eb)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProgramEditorScreen()),
              );
            },
          ),
        ],
      ),
      body: programs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucun programme créé",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Créez votre premier programme d'entraînement !",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProgramEditorScreen()),
                      );
                    },
                    child: const Text("Créer un programme"),
                  )
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: programs.length,
              itemBuilder: (context, index) {
                final program = programs[index];
                return _buildProgramCard(context, program, workoutProvider);
              },
            ),
    );
  }

  Widget _buildProgramCard(
    BuildContext context,
    WorkoutProgram program,
    WorkoutProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: ExpansionTile(
        title: Text(
          program.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          program.description.isEmpty ? "Pas de description" : program.description,
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xff2563eb).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.fitness_center, color: Color(0xff2563eb)),
        ),
        trailing: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        childrenPadding: const EdgeInsets.all(16.0),
        expandedAlignment: Alignment.topLeft,
        children: [
          // List of exercises in the program
          const Text(
            "Exercices inclus :",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...program.exercises.asMap().entries.map((entry) {
            final idx = entry.key;
            final progEx = entry.value;
            final ex = provider.exercises.firstWhere(
              (e) => e.id == progEx.exerciseId,
              orElse: () => Exercise(id: progEx.exerciseId, name: "Exercice Supprimé", categories: const ["Autre"]),
            );

            String targetsString = '';
            if (progEx.type == ExerciseType.reps) {
              targetsString = "${progEx.setsCount} séries × ${progEx.repsCount} reps";
            } else if (progEx.type == ExerciseType.time) {
              targetsString = "${progEx.setsCount} séries × ${_formatDuration(progEx.durationTarget)}";
            } else if (progEx.type == ExerciseType.distance) {
              targetsString = "${progEx.setsCount} séries × ${progEx.distanceTarget} km";
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "${idx + 1}. ",
                    style: const TextStyle(color: Color(0xff2563eb), fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                ex.name,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (ex.videoUrl != null && ex.videoUrl!.trim().isNotEmpty) ...[
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () => YoutubePlayerDialog.show(context, ex.name, ex.videoUrl!),
                                child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 18),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$targetsString (Repos : ${progEx.restTime}s)",
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MultiCategoryBadges(categories: ex.categories, compact: true),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                label: const Text("Modifier", style: TextStyle(color: Colors.grey)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProgramEditorScreen(program: program),
                    ),
                  );
                },
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                label: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
                onPressed: () {
                  _showDeleteConfirm(context, program, provider);
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text("Démarrer"),
                onPressed: () {
                  provider.startSession(program);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
                  );
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, WorkoutProgram program, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le programme ?"),
        content: Text("Êtes-vous sûr de vouloir supprimer '${program.name}' ? Cette action est irréversible."),
        actions: [
          TextButton(
            child: const Text("Annuler"),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
            onPressed: () {
              provider.deleteProgram(program.id);
              Navigator.pop(ctx);
            },
          )
        ],
      ),
    );
  }
}

class ProgramEditorScreen extends StatefulWidget {
  final WorkoutProgram? program;

  const ProgramEditorScreen({super.key, this.program});

  @override
  State<ProgramEditorScreen> createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends State<ProgramEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  List<ProgramExercise> _selectedExercises = [];
  final Map<String, String> _exerciseGroups = {};
  String _modalSearchQuery = '';
  String _modalSelectedCategory = 'Tous';

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      _name = widget.program!.name;
      _description = widget.program!.description;
      _selectedExercises = List.from(widget.program!.exercises);
      if (widget.program!.exerciseGroups != null) {
        _exerciseGroups.addAll(widget.program!.exerciseGroups!);
      }
    } else {
      _name = '';
      _description = '';
      _selectedExercises = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final allExercises = workoutProvider.exercises;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program == null ? "Nouveau Programme" : "Modifier le Programme"),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Header Card for Program Info
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            initialValue: _name,
                            decoration: const InputDecoration(
                              labelText: "Nom du programme",
                              hintText: "Ex: Upper Body Power, Push Day",
                              prefixIcon: Icon(Icons.fitness_center),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return "Veuillez entrer un nom";
                              }
                              return null;
                            },
                            onSaved: (value) => _name = value!.trim(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _description,
                            decoration: const InputDecoration(
                              labelText: "Description (optionnel)",
                              hintText: "Consignes, jours prévus, objectifs...",
                              prefixIcon: Icon(Icons.notes),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 2,
                            onSaved: (value) => _description = value?.trim() ?? '',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Exercises Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Exercices du programme (${_selectedExercises.length})",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_selectedExercises.isNotEmpty)
                        Text(
                          "Maintenez ☰ pour réordonner",
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Reorderable Exercise Cards List
                  if (_selectedExercises.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.add_task, size: 48, color: Colors.grey[500]),
                          const SizedBox(height: 12),
                          const Text(
                            "Aucun exercice dans ce programme",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Cliquez sur le bouton ci-dessous pour ajouter des exercices.",
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _selectedExercises.length,
                      onReorderItem: (oldIndex, newIndex) {
                        setState(() {
                          final item = _selectedExercises.removeAt(oldIndex);
                          _selectedExercises.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, idx) {
                        final progEx = _selectedExercises[idx];
                        final ex = allExercises.firstWhere(
                          (e) => e.id == progEx.exerciseId,
                          orElse: () => Exercise(
                            id: progEx.exerciseId,
                            name: "Exercice Supprimé",
                            categories: const ["Autre"],
                          ),
                        );
                        return _buildExerciseEditorCard(context, idx, progEx, ex);
                      },
                    ),

                  const SizedBox(height: 20),

                  // Main Button to add exercises
                  OutlinedButton.icon(
                    onPressed: () => _showAddExerciseBottomSheet(context, allExercises),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xff2563eb), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_circle, color: Color(0xff2563eb)),
                    label: const Text(
                      "Ajouter des exercices",
                      style: TextStyle(color: Color(0xff2563eb), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),

                  const SizedBox(height: 80), // Padding for sticky bottom save button
                ],
              ),
            ),

            // Sticky Bottom Save Bar
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveProgram,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      widget.program == null
                          ? "Enregistrer le programme (${_selectedExercises.length} ex.)"
                          : "Sauvegarder les modifications",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Carte d'exercice synthétique et élégante dans la liste du programme
  Widget _buildExerciseEditorCard(
    BuildContext context,
    int idx,
    ProgramExercise progEx,
    Exercise ex,
  ) {
    final groupId = _exerciseGroups[ex.id];

    String targetsText = '';
    if (progEx.type == ExerciseType.reps) {
      targetsText = "${progEx.setsCount} séries × ${progEx.repsCount} reps";
    } else if (progEx.type == ExerciseType.time) {
      targetsText = "${progEx.setsCount} séries × ${_formatDuration(progEx.durationTarget)}";
    } else if (progEx.type == ExerciseType.distance) {
      targetsText = "${progEx.setsCount} séries × ${progEx.distanceTarget} km";
    }

    return Card(
      key: ValueKey(progEx.exerciseId),
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: groupId != null && groupId.isNotEmpty
            ? BorderSide(color: _getGroupColor(groupId), width: 1.8)
            : BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: idx,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: Icon(Icons.drag_handle, color: Colors.grey),
                  ),
                ),
                Text(
                  "${idx + 1}.",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff2563eb), fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ex.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ex.videoUrl != null && ex.videoUrl!.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => YoutubePlayerDialog.show(context, ex.name, ex.videoUrl!),
                              child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      MultiCategoryBadges(categories: ex.categories, compact: true),
                    ],
                  ),
                ),

                // Button to configure targets (Séries, Reps/Time, Repos)
                IconButton(
                  icon: const Icon(Icons.tune, color: Color(0xff2563eb)),
                  tooltip: "Régler séries & répétitions/durée",
                  onPressed: () {
                    _showConfigureExerciseTargetDialog(
                      context: context,
                      ex: ex,
                      initialSettings: progEx,
                      onConfirm: (updatedProgramEx) {
                        setState(() {
                          _selectedExercises[idx] = updatedProgramEx;
                        });
                      },
                    );
                  },
                ),

                // Actions popup (Superset, Delete)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'group') {
                      _showGroupDialog(context, ex);
                    } else if (val == 'delete') {
                      setState(() {
                        _selectedExercises.removeAt(idx);
                      });
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'group',
                      child: Row(
                        children: [
                          Icon(Icons.group_work, size: 20, color: Color(0xff2563eb)),
                          SizedBox(width: 8),
                          Text("Superset / Groupe"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          SizedBox(width: 8),
                          Text("Retirer du programme", style: TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            if (groupId != null && groupId.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _getGroupColor(groupId).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.group_work, size: 14, color: _getGroupColor(groupId)),
                    const SizedBox(width: 4),
                    Text(
                      "Groupe : $groupId",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _getGroupColor(groupId)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 10),

            // Synthetic Target Banner with quick edit action
            InkWell(
              onTap: () {
                _showConfigureExerciseTargetDialog(
                  context: context,
                  ex: ex,
                  initialSettings: progEx,
                  onConfirm: (updatedProgramEx) {
                    setState(() {
                      _selectedExercises[idx] = updatedProgramEx;
                    });
                  },
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xff2563eb).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xff2563eb).withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.track_changes, size: 16, color: Color(0xff2563eb)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "$targetsText  •  Repos : ${progEx.restTime}s",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit_note, size: 18, color: Color(0xff2563eb)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProgram() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedExercises.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veuillez sélectionner au moins un exercice")),
        );
        return;
      }

      final provider = Provider.of<WorkoutProvider>(context, listen: false);

      if (widget.program == null) {
        provider.createProgram(_name, _description, _selectedExercises, _exerciseGroups);
      } else {
        final updated = WorkoutProgram(
          id: widget.program!.id,
          name: _name,
          description: _description,
          exercises: _selectedExercises,
          exerciseGroups: _exerciseGroups,
        );
        provider.updateProgram(updated);
      }

      Navigator.pop(context);
    }
  }

  Color _getGroupColor(String groupId) {
    final colors = [
      const Color(0xff2563eb), // Blue
      const Color(0xff10b981), // Green
      const Color(0xfff59e0b), // Amber
      const Color(0xff8b5cf6), // Purple
      const Color(0xffec4899), // Pink
      const Color(0xff06b6d4), // Cyan
    ];
    final hash = groupId.hashCode.abs();
    return colors[hash % colors.length];
  }

  void _showGroupDialog(BuildContext context, Exercise ex) {
    final existingGroups = _exerciseGroups.values
        .where((g) => g.isNotEmpty)
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
                    final isCurrent = _exerciseGroups[ex.id] == group;
                    return ListTile(
                      title: Text(group),
                      leading: Icon(Icons.group_work, color: _getGroupColor(group)),
                      trailing: isCurrent ? const Icon(Icons.check, color: Color(0xff2563eb)) : null,
                      onTap: () {
                        setState(() {
                          _exerciseGroups[ex.id] = group;
                        });
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
                    if (_exerciseGroups.containsKey(ex.id) && _exerciseGroups[ex.id]!.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _exerciseGroups.remove(ex.id);
                          });
                          Navigator.pop(context);
                        },
                        child: const Text("Retirer du groupe", style: TextStyle(color: Colors.redAccent)),
                      )
                    else
                      const SizedBox.shrink(),
                    ElevatedButton(
                      onPressed: () {
                        if (newGroupName != null && newGroupName!.isNotEmpty) {
                          setState(() {
                            _exerciseGroups[ex.id] = newGroupName!;
                          });
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

  /// Dialogue de paramétrage immédiat des séries / répétitions / temps / repos
  void _showConfigureExerciseTargetDialog({
    required BuildContext context,
    required Exercise ex,
    ProgramExercise? initialSettings,
    required ValueChanged<ProgramExercise> onConfirm,
  }) {
    final formKey = GlobalKey<FormState>();

    ExerciseType selectedType = initialSettings?.type ?? ExerciseType.reps;
    int setsCount = initialSettings?.setsCount ?? 3;
    int repsCount = initialSettings?.repsCount ?? 10;
    int restTime = initialSettings?.restTime ?? 90;
    int durationTarget = initialSettings?.durationTarget ?? 0;
    double distanceTarget = initialSettings?.distanceTarget ?? 5.0;


    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff18181c),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[600],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Exercise Name & Categories
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ex.name,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                MultiCategoryBadges(categories: ex.categories, compact: true),
                              ],
                            ),
                          ),
                          if (ex.videoUrl != null && ex.videoUrl!.trim().isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 24),
                              onPressed: () => YoutubePlayerDialog.show(context, ex.name, ex.videoUrl!),
                            ),
                        ],
                      ),

                      const Divider(height: 24),

                      // Choice Chips for Evaluation Mode (Reps, Duration, Distance)
                      const Text(
                        "Mode d'évaluation :",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildDialogChoiceChip(
                            label: "Répétitions",
                            icon: Icons.repeat,
                            isSelected: selectedType == ExerciseType.reps,
                            onTap: () {
                              setDialogState(() {
                                selectedType = ExerciseType.reps;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildDialogChoiceChip(
                            label: "Durée (Chrono)",
                            icon: Icons.timer,
                            isSelected: selectedType == ExerciseType.time,
                            onTap: () {
                              setDialogState(() {
                                selectedType = ExerciseType.time;
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildDialogChoiceChip(
                            label: "Distance",
                            icon: Icons.straighten,
                            isSelected: selectedType == ExerciseType.distance,
                            onTap: () {
                              setDialogState(() {
                                selectedType = ExerciseType.distance;
                              });
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Form Inputs (Séries, Cible, Repos)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Séries
                          Expanded(
                            child: TextFormField(
                              initialValue: setsCount.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Séries",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0) {
                                  return "Min 1";
                                }
                                return null;
                              },
                              onSaved: (val) => setsCount = int.parse(val!),
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Dynamic Target Field
                          if (selectedType == ExerciseType.reps)
                            Expanded(
                              child: TextFormField(
                                initialValue: repsCount.toString(),
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: "Répétitions",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0) {
                                    return "Min 1";
                                  }
                                  return null;
                                },
                                onSaved: (val) => repsCount = int.parse(val!),
                              ),
                            )
                          else if (selectedType == ExerciseType.time)
                            Expanded(
                              flex: 2,
                              child: InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    backgroundColor: const Color(0xff18181c),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (ctx) {
                                      return SizedBox(
                                        height: 260,
                                        child: Column(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  const Text(
                                                    "Temps cible",
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(ctx),
                                                    child: const Text("Valider", style: TextStyle(color: Color(0xff2563eb), fontWeight: FontWeight.bold)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Divider(height: 1),
                                            Expanded(
                                              child: CupertinoTheme(
                                                data: const CupertinoThemeData(brightness: Brightness.dark),
                                                child: CupertinoTimerPicker(
                                                  mode: CupertinoTimerPickerMode.hms,
                                                  initialTimerDuration: Duration(seconds: durationTarget),
                                                  onTimerDurationChanged: (Duration newDuration) {
                                                    setDialogState(() {
                                                      durationTarget = newDuration.inSeconds;
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: "Temps cible",
                                    labelStyle: TextStyle(fontSize: 11, color: Colors.grey),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDuration(durationTarget),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      const Icon(Icons.timer_outlined, size: 18, color: Color(0xff2563eb)),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else if (selectedType == ExerciseType.distance)
                            Expanded(
                              child: TextFormField(
                                initialValue: distanceTarget.toString(),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: "Distance (km)",
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (val) {
                                  if (val == null || val.isEmpty || double.tryParse(val) == null || double.parse(val) <= 0.0) {
                                    return "Min 0.1";
                                  }
                                  return null;
                                },
                                onSaved: (val) => distanceTarget = double.parse(val!),
                              ),
                            ),

                          const SizedBox(width: 12),

                          // Repos
                          Expanded(
                            child: TextFormField(
                              initialValue: restTime.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Repos (s)",
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) < 0) {
                                  return "Min 0";
                                }
                                return null;
                              },
                              onSaved: (val) => restTime = int.parse(val!),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Confirmation Button
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2563eb),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();

                              final result = ProgramExercise(
                                exerciseId: ex.id,
                                type: selectedType,
                                setsCount: setsCount,
                                repsCount: selectedType == ExerciseType.reps ? repsCount : 0,
                                restTime: restTime,
                                durationTarget: selectedType == ExerciseType.time ? durationTarget : 0,
                                distanceTarget: selectedType == ExerciseType.distance ? distanceTarget : 0.0,
                              );

                              onConfirm(result);
                              Navigator.pop(ctx);
                            }
                          },
                          child: Text(
                            initialSettings == null ? "Ajouter l'exercice au programme" : "Enregistrer les réglages",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDialogChoiceChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xff2563eb)
                : const Color(0xff22222a),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xff2563eb) : Colors.grey.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey[300],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Sélecteur d'exercices modernisé sous forme de BottomSheet avec clic déclenchant le paramétrage immédiat
  void _showAddExerciseBottomSheet(BuildContext context, List<Exercise> allExercises) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff121216),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final filtered = allExercises.where((ex) {
              final matchesSearch = ex.name.toLowerCase().contains(_modalSearchQuery.toLowerCase());
              final matchesCategory = _modalSelectedCategory == 'Tous' ||
                  ex.categories.contains(_modalSelectedCategory) ||
                  ex.category == _modalSelectedCategory;
              return matchesSearch && matchesCategory;
            }).toList();

            final filterCategories = ['Tous', ...CategoryHelper.allCategoryNames];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[600],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sélectionner des exercices",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                              ),
                              Text(
                                "${_selectedExercises.length} sélectionné(s)",
                                style: const TextStyle(fontSize: 12, color: Color(0xff2563eb), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xff2563eb), size: 26),
                            tooltip: "Créer un exercice",
                            onPressed: () {
                              final provider = Provider.of<WorkoutProvider>(context, listen: false);
                              _showCreateExerciseDialog(context, provider, setModalState);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Search bar
                      TextField(
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: "Rechercher un exercice...",
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          fillColor: const Color(0xff1e1e24),
                          filled: true,
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            _modalSearchQuery = val;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // Horizontal Category Filter Chips
                      SizedBox(
                        height: 38,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filterCategories.length,
                          itemBuilder: (context, idx) {
                            final cat = filterCategories[idx];
                            final isSelected = _modalSelectedCategory == cat;
                            final info = cat != 'Tous' ? CategoryHelper.getInfo(cat) : null;

                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: FilterChip(
                                selected: isSelected,
                                label: Text(cat),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white
                                      : (info != null ? info.color : Colors.grey[300]),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                avatar: info != null
                                    ? Icon(info.icon, size: 14, color: isSelected ? Colors.white : info.color)
                                    : null,
                                selectedColor: info != null ? info.color : const Color(0xff2563eb),
                                backgroundColor: const Color(0xff1e1e24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                showCheckmark: false,
                                onSelected: (sel) {
                                  setModalState(() {
                                    _modalSelectedCategory = cat;
                                  });
                                },
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Available Exercises List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  "Aucun exercice trouvé",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              )
                            : ListView.builder(
                                controller: scrollController,
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final ex = filtered[index];
                                  final existingProgExIndex = _selectedExercises.indexWhere((e) => e.exerciseId == ex.id);
                                  final isAlreadySelected = existingProgExIndex != -1;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                                    color: isAlreadySelected ? const Color(0xff1e293b) : const Color(0xff1e1e24),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: isAlreadySelected
                                          ? const BorderSide(color: Color(0xff2563eb), width: 1.2)
                                          : BorderSide.none,
                                    ),
                                    child: ListTile(
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ex.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                          if (ex.videoUrl != null && ex.videoUrl!.trim().isNotEmpty) ...[
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () => YoutubePlayerDialog.show(context, ex.name, ex.videoUrl!),
                                              child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 18),
                                            ),
                                          ],
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: MultiCategoryBadges(categories: ex.categories, compact: true),
                                      ),
                                      trailing: isAlreadySelected
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.check_circle, color: Color(0xff2563eb), size: 22),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedExercises.removeWhere((e) => e.exerciseId == ex.id);
                                                    });
                                                    setModalState(() {});
                                                  },
                                                ),
                                              ],
                                            )
                                          : const Icon(Icons.add_circle_outline, color: Color(0xff2563eb), size: 24),
                                      onTap: () {
                                        // Déclencher directement la petite fenêtre de paramétrage (séries, reps, repos)
                                        _showConfigureExerciseTargetDialog(
                                          context: context,
                                          ex: ex,
                                          initialSettings: isAlreadySelected ? _selectedExercises[existingProgExIndex] : null,
                                          onConfirm: (configuredProgEx) {
                                            setState(() {
                                              if (isAlreadySelected) {
                                                _selectedExercises[existingProgExIndex] = configuredProgEx;
                                              } else {
                                                _selectedExercises.add(configuredProgEx);
                                              }
                                            });
                                            setModalState(() {});
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2563eb),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            "Terminer (${_selectedExercises.length} sélectionné(s))",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Dialogue de création d'exercice à la volée avec sélection multi-catégories
  void _showCreateExerciseDialog(BuildContext context, WorkoutProvider provider, StateSetter setModalState) {
    final formKey = GlobalKey<FormState>();
    String name = '';
    List<String> selectedCategories = ['Pectoraux'];
    String notes = '';
    String videoUrl = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Créer un nouvel exercice"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Nom de l'exercice",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? "Requis" : null,
                        onSaved: (val) => name = val!.trim(),
                      ),
                      const SizedBox(height: 16),
                      const Text("Catégorie(s) musculaire(s) :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      CategoryMultiSelect(
                        selectedCategories: selectedCategories,
                        onChanged: (updated) {
                          setDialogState(() {
                            selectedCategories = updated;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Notes / Description (optionnel)",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onSaved: (val) => notes = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Lien vidéo YouTube (optionnel)",
                          hintText: "https://www.youtube.com/watch?v=...",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.video_library_outlined),
                        ),
                        onSaved: (val) => videoUrl = val?.trim() ?? '',
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Annuler"),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  child: const Text("Créer & Sélectionner"),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final cleanNotes = notes.trim().isEmpty ? null : notes.trim();
                      final cleanVideoUrl = videoUrl.trim().isEmpty ? null : videoUrl.trim();

                      await provider.createCustomExercise(
                        name,
                        categories: selectedCategories,
                        notes: cleanNotes,
                        videoUrl: cleanVideoUrl,
                      );

                      final newEx = provider.exercises.lastWhere(
                        (e) => e.name == name,
                        orElse: () => provider.exercises.last,
                      );

                      if (ctx.mounted) Navigator.pop(ctx);

                      // Ouvrir immédiatement le paramétrage pour ce nouvel exercice
                      if (context.mounted) {
                        _showConfigureExerciseTargetDialog(
                          context: context,
                          ex: newEx,
                          initialSettings: null,
                          onConfirm: (configuredProgEx) {
                            setState(() {
                              _selectedExercises.add(configuredProgEx);
                            });
                            setModalState(() {});
                          },
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}

String _formatDuration(int totalSeconds) {
  if (totalSeconds <= 0) return "0s (Définir)";
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;

  final List<String> parts = [];
  if (h > 0) parts.add("${h}h");
  if (m > 0) parts.add("${m}m");
  if (s > 0 || parts.isEmpty) parts.add("${s}s");

  return parts.join(" ");
}
