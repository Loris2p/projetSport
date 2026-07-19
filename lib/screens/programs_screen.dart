import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../models/program_exercise.dart';
import '../providers/workout_provider.dart';
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
              orElse: () => Exercise(id: progEx.exerciseId, name: "Exercice Supprimé", category: "Inconnue"),
            );

            String targetsString = '';
            if (progEx.type == ExerciseType.reps) {
              targetsString = "${progEx.setsCount}x${progEx.repsCount}";
            } else if (progEx.type == ExerciseType.time) {
              final m = progEx.durationTarget ~/ 60;
              final s = progEx.durationTarget % 60;
              final durationString = m > 0 ? "$m:${s.toString().padLeft(2, '0')}" : "${s}s";
              targetsString = "${progEx.setsCount}x$durationString";
            } else if (progEx.type == ExerciseType.distance) {
              targetsString = "${progEx.setsCount}x${progEx.distanceTarget} km";
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Text(
                    "${idx + 1}. ",
                    style: const TextStyle(color: Color(0xff2563eb), fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      "${ex.name} ($targetsString, repos : ${progEx.restTime}s)",
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  if (ex.videoUrl != null && ex.videoUrl!.trim().isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: "Voir la vidéo d'explication",
                      onPressed: () => YoutubePlayerDialog.show(context, ex.name, ex.videoUrl!),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xff2d2d34),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ex.category,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )
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
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Color(0xff2563eb)),
            onPressed: _saveProgram,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Text Fields
                  TextFormField(
                    initialValue: _name,
                    decoration: const InputDecoration(
                      labelText: "Nom du programme",
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xff2563eb)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return "Le nom est requis";
                      }
                      return null;
                    },
                    onSaved: (value) => _name = value!.trim(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _description,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xff2563eb)),
                      ),
                    ),
                    onSaved: (value) => _description = value?.trim() ?? '',
                  ),
                  const SizedBox(height: 24),

                  // Selected Exercises Reorderable List
                  const Text(
                    "Ordre des exercices (glissez-déposez)",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  _selectedExercises.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xff1e1e24),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xff2d2d34)),
                          ),
                          child: Center(
                            child: Text(
                              "Aucun exercice sélectionné. Ajoutez-en ci-dessous !",
                              style: TextStyle(color: Colors.grey[400], fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          // ignore: deprecated_member_use
                          onReorder: _onReorderExercises,
                          children: _selectedExercises.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final progEx = entry.value;
                            final ex = allExercises.firstWhere(
                              (e) => e.id == progEx.exerciseId,
                              orElse: () => Exercise(id: progEx.exerciseId, name: "Exercice Supprimé", category: "Inconnue"),
                            );
                            final hasGroup = _exerciseGroups.containsKey(ex.id) && _exerciseGroups[ex.id]!.isNotEmpty;
                            final groupColor = hasGroup ? _getGroupColor(_exerciseGroups[ex.id]!) : null;

                            return Card(
                              key: ValueKey(progEx.exerciseId),
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              color: const Color(0xff1e1e24),
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
                                        padding: const EdgeInsets.only(bottom: 12.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            ListTile(
                                              dense: true,
                                              leading: const Icon(Icons.drag_handle, color: Colors.grey),
                                              title: Row(
                                                children: [
                                                  Expanded(child: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                                  if (hasGroup) ...[
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: groupColor!.withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                        border: Border.all(color: groupColor, width: 0.8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.group_work, size: 8, color: groupColor),
                                                          const SizedBox(width: 2),
                                                          Text(
                                                            _exerciseGroups[ex.id]!,
                                                            style: TextStyle(
                                                              fontSize: 8,
                                                              fontWeight: FontWeight.bold,
                                                              color: groupColor,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              subtitle: Text(ex.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              trailing: PopupMenuButton<String>(
                                                icon: const Icon(Icons.more_vert, color: Colors.grey),
                                                onSelected: (val) {
                                                  if (val == 'group') {
                                                    _showGroupDialog(context, ex);
                                                  } else if (val == 'delete') {
                                                    setState(() {
                                                      _selectedExercises.removeAt(idx);
                                                      _exerciseGroups.remove(ex.id);
                                                    });
                                                  }
                                                },
                                                itemBuilder: (context) => [
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
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                                                        SizedBox(width: 8),
                                                        Text("Retirer", style: TextStyle(color: Colors.redAccent)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                              child: DropdownButtonFormField<ExerciseType>(
                                                initialValue: progEx.type,
                                                decoration: const InputDecoration(
                                                  labelText: "Type d'évaluation",
                                                  isDense: true,
                                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                  border: OutlineInputBorder(),
                                                ),
                                                items: ExerciseType.values.map((t) {
                                                  return DropdownMenuItem(value: t, child: Text(t.label));
                                                }).toList(),
                                                onChanged: (val) {
                                                  if (val != null) {
                                                    setState(() {
                                                      _selectedExercises[idx] = ProgramExercise(
                                                        exerciseId: progEx.exerciseId,
                                                        type: val,
                                                        setsCount: progEx.setsCount,
                                                        repsCount: val == ExerciseType.reps ? 10 : 0,
                                                        restTime: progEx.restTime,
                                                        durationTarget: val == ExerciseType.time ? 60 : 0,
                                                        distanceTarget: val == ExerciseType.distance ? 5.0 : 0.0,
                                                      );
                                                    });
                                                  }
                                                },
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: progEx.setsCount.toString(),
                                                      keyboardType: TextInputType.number,
                                                      style: const TextStyle(fontSize: 13),
                                                      decoration: const InputDecoration(
                                                        labelText: "Séries",
                                                        labelStyle: TextStyle(fontSize: 11),
                                                        isDense: true,
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                        border: OutlineInputBorder(),
                                                      ),
                                                      validator: (val) {
                                                        if (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0) {
                                                          return "Min 1";
                                                        }
                                                        return null;
                                                      },
                                                      onSaved: (val) {
                                                        final count = int.parse(val!);
                                                        _selectedExercises[idx] = ProgramExercise(
                                                          exerciseId: progEx.exerciseId,
                                                          type: progEx.type,
                                                          setsCount: count,
                                                          repsCount: _selectedExercises[idx].repsCount,
                                                          restTime: _selectedExercises[idx].restTime,
                                                          durationTarget: _selectedExercises[idx].durationTarget,
                                                          distanceTarget: _selectedExercises[idx].distanceTarget,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  if (progEx.type == ExerciseType.reps)
                                                    Expanded(
                                                      child: TextFormField(
                                                        initialValue: progEx.repsCount.toString(),
                                                        keyboardType: TextInputType.number,
                                                        style: const TextStyle(fontSize: 13),
                                                        decoration: const InputDecoration(
                                                          labelText: "Répétitions",
                                                          labelStyle: TextStyle(fontSize: 11),
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                          border: OutlineInputBorder(),
                                                        ),
                                                        validator: (val) {
                                                          if (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0) {
                                                            return "Min 1";
                                                          }
                                                          return null;
                                                        },
                                                        onSaved: (val) {
                                                          final count = int.parse(val!);
                                                          _selectedExercises[idx] = ProgramExercise(
                                                            exerciseId: progEx.exerciseId,
                                                            type: progEx.type,
                                                            setsCount: _selectedExercises[idx].setsCount,
                                                            repsCount: count,
                                                            restTime: _selectedExercises[idx].restTime,
                                                            durationTarget: _selectedExercises[idx].durationTarget,
                                                            distanceTarget: _selectedExercises[idx].distanceTarget,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  else if (progEx.type == ExerciseType.time)
                                                    Expanded(
                                                      child: TextFormField(
                                                        initialValue: progEx.durationTarget.toString(),
                                                        keyboardType: TextInputType.number,
                                                        style: const TextStyle(fontSize: 13),
                                                        decoration: const InputDecoration(
                                                          labelText: "Durée (s)",
                                                          labelStyle: TextStyle(fontSize: 11),
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                          border: OutlineInputBorder(),
                                                        ),
                                                        validator: (val) {
                                                          if (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) <= 0) {
                                                            return "Min 1";
                                                          }
                                                          return null;
                                                        },
                                                        onSaved: (val) {
                                                          final count = int.parse(val!);
                                                          _selectedExercises[idx] = ProgramExercise(
                                                            exerciseId: progEx.exerciseId,
                                                            type: progEx.type,
                                                            setsCount: _selectedExercises[idx].setsCount,
                                                            repsCount: _selectedExercises[idx].repsCount,
                                                            restTime: _selectedExercises[idx].restTime,
                                                            durationTarget: count,
                                                            distanceTarget: _selectedExercises[idx].distanceTarget,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                  else if (progEx.type == ExerciseType.distance)
                                                    Expanded(
                                                      child: TextFormField(
                                                        initialValue: progEx.distanceTarget.toString(),
                                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                        style: const TextStyle(fontSize: 13),
                                                        decoration: const InputDecoration(
                                                          labelText: "Distance (km)",
                                                          labelStyle: TextStyle(fontSize: 11),
                                                          isDense: true,
                                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                          border: OutlineInputBorder(),
                                                        ),
                                                        validator: (val) {
                                                          if (val == null || val.isEmpty || double.tryParse(val) == null || double.parse(val) <= 0.0) {
                                                            return "Min 0.1";
                                                          }
                                                          return null;
                                                        },
                                                        onSaved: (val) {
                                                          final dist = double.parse(val!);
                                                          _selectedExercises[idx] = ProgramExercise(
                                                            exerciseId: progEx.exerciseId,
                                                            type: progEx.type,
                                                            setsCount: _selectedExercises[idx].setsCount,
                                                            repsCount: _selectedExercises[idx].repsCount,
                                                            restTime: _selectedExercises[idx].restTime,
                                                            durationTarget: _selectedExercises[idx].durationTarget,
                                                            distanceTarget: dist,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: TextFormField(
                                                      initialValue: progEx.restTime.toString(),
                                                      keyboardType: TextInputType.number,
                                                      style: const TextStyle(fontSize: 13),
                                                      decoration: const InputDecoration(
                                                        labelText: "Repos (s)",
                                                        labelStyle: TextStyle(fontSize: 11),
                                                        isDense: true,
                                                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                                        border: OutlineInputBorder(),
                                                      ),
                                                      validator: (val) {
                                                        if (val == null || val.isEmpty || int.tryParse(val) == null || int.parse(val) < 0) {
                                                          return "Min 0";
                                                        }
                                                        return null;
                                                      },
                                                      onSaved: (val) {
                                                        final count = int.parse(val!);
                                                        _selectedExercises[idx] = ProgramExercise(
                                                          exerciseId: progEx.exerciseId,
                                                          type: progEx.type,
                                                          setsCount: _selectedExercises[idx].setsCount,
                                                          repsCount: _selectedExercises[idx].repsCount,
                                                          restTime: count,
                                                          durationTarget: _selectedExercises[idx].durationTarget,
                                                          distanceTarget: _selectedExercises[idx].distanceTarget,
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddExerciseBottomSheet(context, allExercises),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text("Ajouter un exercice"),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedExercises.removeAt(oldIndex);
      _selectedExercises.insert(newIndex, item);
    });
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
      const Color(0xff8b5cf6), // Purple
      const Color(0xfff59e0b), // Amber/Orange
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
              final matchesSearch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
              final matchesCategory = _selectedCategory == 'Tous' || ex.category == _selectedCategory;
              return matchesSearch && matchesCategory;
            }).toList();

            final categories = ['Tous', ...allExercises.map((e) => e.category).toSet()];

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.8,
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
                      const Text(
                        "Sélectionner des exercices",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: "Rechercher...",
                                hintStyle: const TextStyle(color: Colors.grey),
                                prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                fillColor: const Color(0xff1e1e24),
                                filled: true,
                              ),
                              onChanged: (val) {
                                setModalState(() {
                                  _searchQuery = val;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedCategory,
                            dropdownColor: const Color(0xff1e1e24),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.filter_list, color: Colors.white),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setModalState(() {
                                  _selectedCategory = newValue;
                                });
                              }
                            },
                            items: categories.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value, style: const TextStyle(fontSize: 14, color: Colors.white)),
                              );
                            }).toList(),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final ex = filtered[index];
                            final isAlreadySelected = _selectedExercises.any((e) => e.exerciseId == ex.id);

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              color: const Color(0xff1e1e24),
                              child: ListTile(
                                title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                subtitle: Text(ex.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                trailing: isAlreadySelected
                                    ? const Icon(Icons.check_circle, color: Color(0xff2563eb))
                                    : const Icon(Icons.add_circle_outline, color: Colors.grey),
                                onTap: () {
                                  setState(() {
                                    if (isAlreadySelected) {
                                      _selectedExercises.removeWhere((e) => e.exerciseId == ex.id);
                                    } else {
                                      _selectedExercises.add(
                                        ProgramExercise(
                                          exerciseId: ex.id,
                                          type: ExerciseType.reps,
                                          setsCount: 3,
                                          repsCount: 10,
                                          restTime: 90,
                                          durationTarget: 0,
                                          distanceTarget: 0.0,
                                        ),
                                      );
                                    }
                                  });
                                  setModalState(() {});
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff2563eb),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text("Fermer", style: TextStyle(color: Colors.white)),
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
}
