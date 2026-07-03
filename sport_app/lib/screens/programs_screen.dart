import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/workout_program.dart';
import '../providers/workout_provider.dart';
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
            final ex = entry.value;
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
                      ex.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
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
  List<Exercise> _selectedExercises = [];
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  @override
  void initState() {
    super.initState();
    if (widget.program != null) {
      _name = widget.program!.name;
      _description = widget.program!.description;
      _selectedExercises = List.from(widget.program!.exercises);
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

    // Filter exercises based on search query and category
    final filteredExercises = allExercises.where((ex) {
      final matchesSearch = ex.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'Tous' || ex.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Get unique categories for filtering
    final categories = ['Tous', ...allExercises.map((e) => e.category).toSet()];

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
                      : SizedBox(
                          height: 220,
                          child: ReorderableListView(
                            // ignore: deprecated_member_use
                            onReorder: _onReorderExercises,
                            children: _selectedExercises.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final ex = entry.value;
                              return Card(
                                key: ValueKey(ex.id),
                                margin: const EdgeInsets.symmetric(vertical: 4.0),
                                color: const Color(0xff1e1e24),
                                child: ListTile(
                                  leading: const Icon(Icons.drag_handle, color: Colors.grey),
                                  title: Text(ex.name),
                                  subtitle: Text(ex.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                                    onPressed: () {
                                      setState(() {
                                        _selectedExercises.removeAt(idx);
                                      });
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                  const SizedBox(height: 24),

                  // Exercise Catalog Picker Title
                  const Text(
                    "Sélectionner des exercices",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),

                  // Search & Filters inside Picker
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Rechercher...",
                            prefixIcon: const Icon(Icons.search, size: 20),
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            fillColor: const Color(0xff1e1e24),
                            filled: true,
                          ),
                          onChanged: (val) {
                            setState(() {
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
                        icon: const Icon(Icons.filter_list),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedCategory = newValue;
                            });
                          }
                        },
                        items: categories.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ex = filteredExercises[index];
                    final isAlreadySelected = _selectedExercises.any((e) => e.id == ex.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        title: Text(ex.name),
                        subtitle: Text(ex.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: isAlreadySelected
                            ? const Icon(Icons.check_circle, color: Color(0xff2563eb))
                            : const Icon(Icons.add_circle_outline, color: Colors.grey),
                        onTap: () {
                          setState(() {
                            if (isAlreadySelected) {
                              _selectedExercises.removeWhere((e) => e.id == ex.id);
                            } else {
                              _selectedExercises.add(ex);
                            }
                          });
                        },
                      ),
                    );
                  },
                  childCount: filteredExercises.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 32),
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
        provider.createProgram(_name, _description, _selectedExercises);
      } else {
        final updated = WorkoutProgram(
          id: widget.program!.id,
          name: _name,
          description: _description,
          exercises: _selectedExercises,
        );
        provider.updateProgram(updated);
      }

      Navigator.pop(context);
    }
  }
}
