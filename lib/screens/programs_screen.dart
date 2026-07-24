import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/program_exercise.dart';
import '../models/exercise_set.dart';
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.play_circle_fill, color: Color(0xff2563eb), size: 28),
              tooltip: "Démarrer le programme",
              onPressed: () {
                provider.startSession(program);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
                );
              },
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
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

            String targetsString = _getProgramExerciseSummary(progEx);


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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey),
                    tooltip: "Modifier",
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProgramEditorScreen(program: program),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    tooltip: "Supprimer",
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      _showDeleteConfirm(context, program, provider);
                    },
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff2563eb),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text("Démarrer", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                            textCapitalization: TextCapitalization.sentences,
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
                            onSaved: (value) {
                              final trimmed = value!.trim();
                              _name = trimmed.isNotEmpty ? (trimmed[0].toUpperCase() + trimmed.substring(1)) : trimmed;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _description,
                            textCapitalization: TextCapitalization.sentences,

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
    final groupId = progEx.groupId ?? _exerciseGroups[ex.id];

    String targetsText = _getProgramExerciseSummary(progEx);

    return Card(
      key: ObjectKey(progEx),
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

                // Actions popup (Duplicate, Superset, Delete)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (val) {
                    if (val == 'duplicate') {
                      setState(() {
                        _selectedExercises.insert(idx + 1, progEx.copyWith());
                      });
                    } else if (val == 'group') {
                      _showGroupDialogForProgEx(context, idx, progEx, ex);
                    } else if (val == 'delete') {
                      setState(() {
                        _selectedExercises.removeAt(idx);
                      });
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20, color: Color(0xff2563eb)),
                          SizedBox(width: 8),
                          Text("Dupliquer l'exercice"),
                        ],
                      ),
                    ),
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


  void _showGroupDialogForProgEx(BuildContext context, int idx, ProgramExercise progEx, Exercise ex) {
    final existingGroups = <String>{
      ..._selectedExercises.map((e) => e.groupId ?? '').where((g) => g.isNotEmpty),
      ..._exerciseGroups.values.where((g) => g.isNotEmpty),
    }.toList();

    final currentGroup = progEx.groupId ?? _exerciseGroups[ex.id];

    showDialog(
      context: context,
      builder: (context) {
        String? newGroupName;
        return AlertDialog(
          title: Text("Associer à un groupe (${ex.name})"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (existingGroups.isNotEmpty) ...[
                  const Text("Groupes existants :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...existingGroups.map((group) {
                    final isCurrent = currentGroup == group;
                    return ListTile(
                      title: Text(group),
                      leading: Icon(Icons.group_work, color: _getGroupColor(group)),
                      trailing: isCurrent ? const Icon(Icons.check, color: Color(0xff2563eb)) : null,
                      onTap: () {
                        setState(() {
                          _selectedExercises[idx] = progEx.copyWith(groupId: group);
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
                    if (currentGroup != null && currentGroup.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedExercises[idx] = progEx.copyWith(clearGroupId: true);
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
                            _selectedExercises[idx] = progEx.copyWith(groupId: newGroupName);
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

    int? setsCount = initialSettings?.setsCount;
    int? repsCount = initialSettings?.repsCount;
    int? restTime = initialSettings?.restTime;
    int? durationTarget = initialSettings?.durationTarget;
    double? distanceTarget = initialSettings?.distanceTarget;
    int? workTime = initialSettings?.workTime;
    int? intervalRestTime = initialSettings?.intervalRestTime;

    String tempoCode = initialSettings?.tempoCode ?? '';
    String videoUrl = initialSettings?.videoUrl ?? ex.videoUrl ?? '';

    // Initialisation des paliers/étapes cardio & fractionné
    final List<ExerciseSet> cardioSteps = [];
    if (initialSettings?.customSets != null && initialSettings!.customSets!.isNotEmpty) {
      cardioSteps.addAll(
        initialSettings.customSets!.map(
          (s) => ExerciseSet(
            id: s.id,
            duration: s.duration,
            distance: s.distance,
            speed: s.speed,
            incline: s.incline,
            workTime: s.workTime,
            intervalRest: s.intervalRest,
          ),
        ),
      );
    } else {
      cardioSteps.add(
        ExerciseSet(
          id: '1',
          duration: initialSettings?.durationTarget ?? 600,
          distance: initialSettings?.distanceTarget ?? 0.0,
          speed: initialSettings?.speedTarget ?? 4.0,
          incline: initialSettings?.inclineTarget ?? 3.0,
          workTime: initialSettings?.workTime ?? 30,
          intervalRest: initialSettings?.intervalRestTime ?? 15,
        ),
      );
    }

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

                      // Selector for all 10 Exercise Types
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Type d'application sur le terrain :",
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            selectedType.label,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff2563eb)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Horizontal Scrollable Grid of Types
                      SizedBox(
                        height: 75,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: ExerciseType.values.length,
                          itemBuilder: (context, i) {
                            final type = ExerciseType.values[i];
                            final isSel = type == selectedType;
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  selectedType = type;
                                });
                              },
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xff2563eb).withValues(alpha: 0.25)
                                      : const Color(0xff22222a),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel ? const Color(0xff2563eb) : Colors.grey.withValues(alpha: 0.2),
                                    width: isSel ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(type.icon, size: 20, color: isSel ? const Color(0xff2563eb) : Colors.grey),
                                    const SizedBox(height: 4),
                                    Text(
                                      type.label,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                        color: isSel ? Colors.white : Colors.grey[300],
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xff22222a),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          selectedType.description,
                          style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Dynamic Fields based on Selected Type
                      _buildDynamicTargetFields(
                        context: context,
                        setDialogState: setDialogState,
                        type: selectedType,
                        setsCount: setsCount,
                        onSetsChanged: (v) => setsCount = v,
                        repsCount: repsCount,
                        onRepsChanged: (v) => repsCount = v,
                        restTime: restTime,
                        onRestChanged: (v) => restTime = v,
                        durationTarget: durationTarget,
                        onDurationChanged: (v) => durationTarget = v,
                        distanceTarget: distanceTarget,
                        onDistanceChanged: (v) => distanceTarget = v,
                        workTime: workTime,
                        onWorkTimeChanged: (v) => workTime = v,
                        intervalRestTime: intervalRestTime,
                        onIntervalRestChanged: (v) => intervalRestTime = v,
                        tempoCode: tempoCode,
                        onTempoChanged: (v) => tempoCode = v,
                        videoUrl: videoUrl,
                        onVideoUrlChanged: (v) => videoUrl = v,
                        cardioSteps: cardioSteps,
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

                              int finalSetsCount = 1;
                              final currentSets = setsCount;
                              if (selectedType == ExerciseType.reps ||
                                  selectedType == ExerciseType.isometry ||
                                  selectedType == ExerciseType.tempo ||
                                  selectedType == ExerciseType.circuit) {
                                finalSetsCount = currentSets ?? 3;
                              } else if (selectedType == ExerciseType.cardio || selectedType == ExerciseType.intervals) {
                                finalSetsCount = cardioSteps.length;
                              } else if (currentSets != null && currentSets > 0) {
                                finalSetsCount = currentSets;
                              }

                              List<ExerciseSet>? finalCustomSets;
                              if (selectedType == ExerciseType.cardio || selectedType == ExerciseType.intervals) {
                                finalCustomSets = List<ExerciseSet>.from(cardioSteps);
                              }

                              final result = ProgramExercise(
                                exerciseId: ex.id,
                                type: selectedType,
                                setsCount: finalSetsCount,
                                repsCount: repsCount ?? 10,
                                restTime: restTime ?? 0,
                                durationTarget: cardioSteps.isNotEmpty ? cardioSteps.first.duration : (durationTarget ?? 30),
                                distanceTarget: cardioSteps.isNotEmpty ? cardioSteps.first.distance : (distanceTarget ?? 5.0),
                                speedTarget: cardioSteps.isNotEmpty ? cardioSteps.first.speed : 0.0,
                                inclineTarget: cardioSteps.isNotEmpty ? cardioSteps.first.incline : 0.0,
                                workTime: cardioSteps.isNotEmpty ? cardioSteps.first.workTime : (workTime ?? 30),
                                intervalRestTime: cardioSteps.isNotEmpty ? cardioSteps.first.intervalRest : (intervalRestTime ?? 0),
                                tempoCode: tempoCode.isNotEmpty ? tempoCode : '3010',
                                videoUrl: videoUrl.isNotEmpty ? videoUrl : null,
                                customSets: finalCustomSets,
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

  /// Générateur dynamique des champs de formulaire de réglage selon le type d'exercice
  Widget _buildDynamicTargetFields({
    required BuildContext context,
    required StateSetter setDialogState,
    required ExerciseType type,
    required int? setsCount,
    required ValueChanged<int> onSetsChanged,
    required int? restTime,
    required ValueChanged<int> onRestChanged,
    required int? repsCount,
    required ValueChanged<int> onRepsChanged,
    required int? durationTarget,
    required ValueChanged<int> onDurationChanged,
    required double? distanceTarget,
    required ValueChanged<double> onDistanceChanged,
    required int? workTime,
    required ValueChanged<int> onWorkTimeChanged,
    required int? intervalRestTime,
    required ValueChanged<int> onIntervalRestChanged,
    required String tempoCode,
    required ValueChanged<String> onTempoChanged,
    required String videoUrl,
    required ValueChanged<String> onVideoUrlChanged,
    required List<ExerciseSet> cardioSteps,
  }) {
    switch (type) {
      case ExerciseType.reps:
      case ExerciseType.circuit:
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: setsCount != null && setsCount > 0 ? setsCount.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Séries", hintText: "ex: 3", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onSetsChanged(val == null || val.trim().isEmpty ? 3 : (int.tryParse(val.trim()) ?? 3)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: repsCount != null && repsCount > 0 ? repsCount.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Répétitions", hintText: "ex: 10", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onRepsChanged(val == null || val.trim().isEmpty ? 10 : (int.tryParse(val.trim()) ?? 10)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: restTime != null && restTime > 0 ? restTime.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Repos (s)", hintText: "ex: 60", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onRestChanged(val == null || val.trim().isEmpty ? 0 : (int.tryParse(val.trim()) ?? 0)),
              ),
            ),
          ],
        );

      case ExerciseType.isometry:
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: setsCount != null && setsCount > 0 ? setsCount.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Séries", hintText: "ex: 3", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onSetsChanged(val == null || val.trim().isEmpty ? 3 : (int.tryParse(val.trim()) ?? 3)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: durationTarget != null && durationTarget > 0 ? durationTarget.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Durée (s)", hintText: "ex: 30", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onDurationChanged(val == null || val.trim().isEmpty ? 30 : (int.tryParse(val.trim()) ?? 30)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: restTime != null && restTime > 0 ? restTime.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Repos (s)", hintText: "ex: 60", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onRestChanged(val == null || val.trim().isEmpty ? 0 : (int.tryParse(val.trim()) ?? 0)),
              ),
            ),
          ],
        );

      case ExerciseType.cardio:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Paliers & Étapes Cardio :",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "Durée, vitesse (km/h) & pente (%)",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...cardioSteps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              final durMin = step.duration > 0 ? (step.duration / 60.0) : 10.0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff22222a),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xff2563eb).withValues(alpha: 0.2),
                          child: Text(
                            "${idx + 1}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff2563eb)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Étape ${idx + 1}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Spacer(),
                        if (cardioSteps.length > 1)
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                cardioSteps.removeAt(idx);
                              });
                            },
                            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: durMin.toStringAsFixed(1).replaceAll('.0', ''),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: "Durée (min)", hintText: "ex: 10", border: OutlineInputBorder(), isDense: true),
                            onChanged: (val) {
                              final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 10.0;
                              step.duration = (parsed * 60).toInt();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: step.speed > 0 ? step.speed.toStringAsFixed(1).replaceAll('.0', '') : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: "Vitesse (km/h)", hintText: "ex: 4.0", border: OutlineInputBorder(), isDense: true),
                            onChanged: (val) {
                              step.speed = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: step.incline > 0 ? step.incline.toStringAsFixed(1).replaceAll('.0', '') : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: "Pente (%)", hintText: "ex: 3.0", border: OutlineInputBorder(), isDense: true),
                            onChanged: (val) {
                              step.incline = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff2563eb),
                  side: const BorderSide(color: Color(0xff2563eb)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setDialogState(() {
                    double lastSpeed = cardioSteps.isNotEmpty ? cardioSteps.last.speed : 4.0;
                    double lastIncline = cardioSteps.isNotEmpty ? cardioSteps.last.incline : 3.0;
                    int lastDuration = cardioSteps.isNotEmpty ? cardioSteps.last.duration : 600;
                    cardioSteps.add(ExerciseSet(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      duration: lastDuration,
                      speed: lastSpeed,
                      incline: lastIncline,
                    ));
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Ajouter un palier / une étape", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );

      case ExerciseType.intervals:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Tours & Paliers Fractionné / HIIT :",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                Text(
                  "Effort, repos, km/h & pente",
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...cardioSteps.asMap().entries.map((entry) {
              final idx = entry.key;
              final step = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xff22222a),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: const Color(0xff2563eb).withValues(alpha: 0.2),
                          child: Text(
                            "${idx + 1}",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff2563eb)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Tour ${idx + 1}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const Spacer(),
                        if (cardioSteps.length > 1)
                          InkWell(
                            onTap: () {
                              setDialogState(() {
                                cardioSteps.removeAt(idx);
                              });
                            },
                            child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: (step.workTime > 0 ? step.workTime : 30).toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Effort (s)", hintText: "30", border: OutlineInputBorder(), isDense: true),
                            onChanged: (val) {
                              step.workTime = int.tryParse(val.trim()) ?? 30;
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            initialValue: (step.intervalRest > 0 ? step.intervalRest : 15).toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: "Repos (s)", hintText: "15", border: OutlineInputBorder(), isDense: true),
                            onChanged: (val) {
                              step.intervalRest = int.tryParse(val.trim()) ?? 15;
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            initialValue: step.speed > 0 ? step.speed.toStringAsFixed(1).replaceAll('.0', '') : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: "Vitesse (km/h)", hintText: "12.0", border: OutlineInputBorder(), isDense: true),
                            onChanged: (val) {
                              step.speed = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                            },
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: TextFormField(
                            initialValue: step.incline > 0 ? step.incline.toStringAsFixed(1).replaceAll('.0', '') : '',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: "Pente (%)", hintText: "0.0", border: OutlineInputBorder(), isDense: true),
                            onChanged: (val) {
                              step.incline = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xff2563eb),
                  side: const BorderSide(color: Color(0xff2563eb)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setDialogState(() {
                    int lastWork = cardioSteps.isNotEmpty ? cardioSteps.last.workTime : 30;
                    int lastRest = cardioSteps.isNotEmpty ? cardioSteps.last.intervalRest : 15;
                    double lastSpeed = cardioSteps.isNotEmpty ? cardioSteps.last.speed : 0.0;
                    double lastIncline = cardioSteps.isNotEmpty ? cardioSteps.last.incline : 0.0;
                    cardioSteps.add(ExerciseSet(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      workTime: lastWork,
                      intervalRest: lastRest,
                      speed: lastSpeed,
                      incline: lastIncline,
                    ));
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text("Ajouter un tour / intervalle", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );

      case ExerciseType.amrap:
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: durationTarget != null && durationTarget > 0 ? durationTarget.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Chrono max (s)", hintText: "ex: 300 (5 min)", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onDurationChanged(val == null || val.trim().isEmpty ? 300 : (int.tryParse(val.trim()) ?? 300)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: restTime != null && restTime > 0 ? restTime.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Repos (s)", hintText: "ex: 60", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onRestChanged(val == null || val.trim().isEmpty ? 0 : (int.tryParse(val.trim()) ?? 0)),
              ),
            ),
          ],
        );

      case ExerciseType.emom:
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: durationTarget != null && durationTarget > 0 ? (durationTarget ~/ 60).toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Durée (min)", hintText: "ex: 10", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onDurationChanged(val == null || val.trim().isEmpty ? 600 : ((int.tryParse(val.trim()) ?? 10) * 60)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: repsCount != null && repsCount > 0 ? repsCount.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Reps / min", hintText: "ex: 10", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onRepsChanged(val == null || val.trim().isEmpty ? 10 : (int.tryParse(val.trim()) ?? 10)),
              ),
            ),
          ],
        );

      case ExerciseType.forTime:
        return Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: repsCount != null && repsCount > 0 ? repsCount.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Reps total", hintText: "ex: 100", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onRepsChanged(val == null || val.trim().isEmpty ? 100 : (int.tryParse(val.trim()) ?? 100)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: durationTarget != null && durationTarget > 0 ? durationTarget.toString() : '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Time Cap (s)", hintText: "ex: 600 (0=Illimité)", border: OutlineInputBorder(), isDense: true),
                validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                onSaved: (val) => onDurationChanged(val == null || val.trim().isEmpty ? 0 : (int.tryParse(val.trim()) ?? 0)),
              ),
            ),
          ],
        );

      case ExerciseType.video:
        return Column(
          children: [
            TextFormField(
              initialValue: durationTarget != null && durationTarget > 0 ? (durationTarget ~/ 60).toString() : '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Durée du cours (min)", hintText: "ex: 20", border: OutlineInputBorder(), isDense: true),
              validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
              onSaved: (val) => onDurationChanged(val == null || val.trim().isEmpty ? 1200 : ((int.tryParse(val.trim()) ?? 20) * 60)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: videoUrl,
              decoration: const InputDecoration(labelText: "URL Média / Cours", hintText: "ex: https://youtube.com/...", border: OutlineInputBorder(), isDense: true),
              onSaved: (val) => onVideoUrlChanged(val?.trim() ?? ''),
            ),
          ],
        );

      case ExerciseType.tempo:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: setsCount != null && setsCount > 0 ? setsCount.toString() : '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Séries", hintText: "ex: 4", border: OutlineInputBorder(), isDense: true),
                    validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                    onSaved: (val) => onSetsChanged(val == null || val.trim().isEmpty ? 4 : (int.tryParse(val.trim()) ?? 4)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: repsCount != null && repsCount > 0 ? repsCount.toString() : '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Répétitions", hintText: "ex: 10", border: OutlineInputBorder(), isDense: true),
                    validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
                    onSaved: (val) => onRepsChanged(val == null || val.trim().isEmpty ? 10 : (int.tryParse(val.trim()) ?? 10)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: tempoCode,
                    decoration: const InputDecoration(labelText: "Tempo", hintText: "ex: 3010", border: OutlineInputBorder(), isDense: true),
                    onSaved: (val) => onTempoChanged(val == null || val.trim().isEmpty ? '3010' : val.trim()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: restTime != null && restTime > 0 ? restTime.toString() : '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Repos (s)", hintText: "ex: 60", border: OutlineInputBorder(), isDense: true),
              validator: (val) => val != null && val.trim().isNotEmpty && int.tryParse(val.trim()) == null ? "Invalide" : null,
              onSaved: (val) => onRestChanged(val == null || val.trim().isEmpty ? 0 : (int.tryParse(val.trim()) ?? 0)),
            ),
          ],
        );
    }
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
        bool isGridView = false;
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
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(isGridView ? Icons.view_list : Icons.grid_view, color: const Color(0xff2563eb)),
                                tooltip: isGridView ? "Vue Liste" : "Vue Grille (3 colonnes)",
                                onPressed: () {
                                  setModalState(() {
                                    isGridView = !isGridView;
                                  });
                                },
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

                      // Available Exercises List / Grid
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  "Aucun exercice trouvé",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              )
                            : isGridView
                                ? GridView.builder(
                                    controller: scrollController,
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                      childAspectRatio: 0.82,
                                    ),
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final ex = filtered[index];
                                      final addedCount = _selectedExercises.where((e) => e.exerciseId == ex.id).length;
                                      final isAlreadySelected = addedCount > 0;
                                      final mainCat = ex.categories.isNotEmpty ? ex.categories.first : ex.category;
                                      final catInfo = CategoryHelper.getInfo(mainCat);

                                      return InkWell(
                                        onTap: () {
                                          _showConfigureExerciseTargetDialog(
                                            context: context,
                                            ex: ex,
                                            initialSettings: null,
                                            onConfirm: (configuredProgEx) {
                                              setState(() {
                                                _selectedExercises.add(configuredProgEx);
                                              });
                                              setModalState(() {});
                                            },
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(10),
                                        child: Card(
                                          margin: EdgeInsets.zero,
                                          color: isAlreadySelected ? const Color(0xff1e293b) : const Color(0xff1e1e24),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            side: isAlreadySelected
                                                ? const BorderSide(color: Color(0xff2563eb), width: 1.5)
                                                : BorderSide(color: catInfo.color.withValues(alpha: 0.3), width: 1),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(7.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Icon(catInfo.icon, size: 13, color: catInfo.color),
                                                    if (addedCount > 0)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xff2563eb),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                        child: Text(
                                                          "x$addedCount",
                                                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                                        ),
                                                      )
                                                    else
                                                      const Icon(Icons.add_circle_outline, size: 16, color: Color(0xff2563eb)),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Text(
                                                  ex.name,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  mainCat,
                                                  style: TextStyle(fontSize: 9, color: catInfo.color, fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const Spacer(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : ListView.builder(
                                    controller: scrollController,
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final ex = filtered[index];
                                      final addedCount = _selectedExercises.where((e) => e.exerciseId == ex.id).length;
                                      final isAlreadySelected = addedCount > 0;

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
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (addedCount > 0) ...[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xff2563eb).withValues(alpha: 0.2),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: const Color(0xff2563eb)),
                                                  ),
                                                  child: Text(
                                                    "x$addedCount",
                                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                                const SizedBox(width: 2),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, color: Color(0xff2563eb), size: 22),
                                                  tooltip: "Ajouter une autre occurrence",
                                                  onPressed: () {
                                                    _showConfigureExerciseTargetDialog(
                                                      context: context,
                                                      ex: ex,
                                                      initialSettings: null,
                                                      onConfirm: (configuredProgEx) {
                                                        setState(() {
                                                          _selectedExercises.add(configuredProgEx);
                                                        });
                                                        setModalState(() {});
                                                      },
                                                    );
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                                  tooltip: "Retirer toutes les occurrences",
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedExercises.removeWhere((e) => e.exerciseId == ex.id);
                                                    });
                                                    setModalState(() {});
                                                  },
                                                ),
                                              ] else
                                                const Icon(Icons.add_circle_outline, color: Color(0xff2563eb), size: 24),
                                            ],
                                          ),
                                          onTap: () {
                                            _showConfigureExerciseTargetDialog(
                                              context: context,
                                              ex: ex,
                                              initialSettings: null,
                                              onConfirm: (configuredProgEx) {
                                                setState(() {
                                                  _selectedExercises.add(configuredProgEx);
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
    List<String> selectedCategories = [];

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
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: "Nom de l'exercice",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? "Requis" : null,
                        onSaved: (val) {
                          final trimmed = val!.trim();
                          name = trimmed.isNotEmpty ? (trimmed[0].toUpperCase() + trimmed.substring(1)) : trimmed;
                        },
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

String _formatCardioStepSummary(ExerciseSet set, {bool isIntervals = false}) {
  List<String> parts = [];
  if (isIntervals) {
    parts.add("${set.workTime}s / ${set.intervalRest}s");
  } else {
    if (set.duration > 0) {
      parts.add(_formatDuration(set.duration));
    } else if (set.distance > 0) {
      parts.add("${set.distance.toStringAsFixed(1).replaceAll('.0', '')} km");
    }
  }
  if (set.speed > 0) {
    parts.add("${set.speed.toStringAsFixed(1).replaceAll('.0', '')}km/h");
  }
  if (set.incline > 0) {
    parts.add("${set.incline.toStringAsFixed(1).replaceAll('.0', '')}%");
  }
  return parts.isEmpty ? "Étape" : parts.join(" ");
}

String _getProgramExerciseSummary(ProgramExercise progEx) {
  switch (progEx.type) {
    case ExerciseType.reps:
      return "${progEx.setsCount} séries × ${progEx.repsCount} reps";
    case ExerciseType.isometry:
      return "${progEx.setsCount} séries × ${_formatDuration(progEx.durationTarget)} (Isométrie)";
    case ExerciseType.cardio:
      if (progEx.customSets != null && progEx.customSets!.isNotEmpty) {
        return progEx.customSets!.map((s) => _formatCardioStepSummary(s)).join(" ➔ ");
      }
      List<String> cardioMetrics = [];
      if (progEx.durationTarget > 0) cardioMetrics.add(_formatDuration(progEx.durationTarget));
      if (progEx.distanceTarget > 0) cardioMetrics.add("${progEx.distanceTarget.toStringAsFixed(1).replaceAll('.0', '')} km");
      if (progEx.speedTarget > 0) cardioMetrics.add("${progEx.speedTarget.toStringAsFixed(1).replaceAll('.0', '')}km/h");
      if (progEx.inclineTarget > 0) cardioMetrics.add("${progEx.inclineTarget.toStringAsFixed(1).replaceAll('.0', '')}%");

      String sub = cardioMetrics.isEmpty ? "Cardio" : cardioMetrics.join(" ");
      return progEx.setsCount > 1 ? "${progEx.setsCount} séries × $sub" : sub;

    case ExerciseType.intervals:
      if (progEx.customSets != null && progEx.customSets!.isNotEmpty) {
        return progEx.customSets!.map((s) => _formatCardioStepSummary(s, isIntervals: true)).join(" ➔ ");
      }
      String speedIncline = "";
      if (progEx.speedTarget > 0) speedIncline += " ${progEx.speedTarget.toStringAsFixed(1).replaceAll('.0', '')}km/h";
      if (progEx.inclineTarget > 0) speedIncline += " ${progEx.inclineTarget.toStringAsFixed(1).replaceAll('.0', '')}%";
      return "${progEx.setsCount} tours (${progEx.workTime}s effort / ${progEx.intervalRestTime}s repos$speedIncline)";
    case ExerciseType.amrap:
      return "AMRAP ${_formatDuration(progEx.durationTarget)}";
    case ExerciseType.emom:
      return "EMOM ${progEx.durationTarget ~/ 60} min (${progEx.repsCount} reps/min)";
    case ExerciseType.forTime:
      return "For Time (${progEx.repsCount} reps, Cap ${_formatDuration(progEx.durationTarget)})";
    case ExerciseType.video:
      return "Cours vidéo (${_formatDuration(progEx.durationTarget)})";
    case ExerciseType.tempo:
      return "${progEx.setsCount} séries × ${progEx.repsCount} reps (Tempo ${progEx.tempoCode})";
    case ExerciseType.circuit:
      return "${progEx.setsCount} séries × ${progEx.repsCount > 0 ? '${progEx.repsCount} reps' : _formatDuration(progEx.durationTarget)} (Circuit)";
  }
}

