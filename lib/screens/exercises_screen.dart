import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

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
        title: const Text("Exercices"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xff2563eb)),
            onPressed: () => _showExerciseDialog(context, null, workoutProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Rechercher un exercice...",
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
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _selectedCategory,
                  dropdownColor: const Color(0xff1e1e24),
                  underline: const SizedBox(),
                  icon: const Icon(Icons.filter_list, color: Color(0xff2563eb)),
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
          ),
          
          // Exercises List
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child: Text(
                      "Aucun exercice trouvé",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final ex = filteredExercises[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10.0),
                        child: ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ex.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (!ex.isCustom)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Public",
                                    style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff2563eb).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    "Privé",
                                    style: TextStyle(fontSize: 9, color: Color(0xff2563eb), fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(ex.category, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              if (ex.notes != null && ex.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  ex.notes!,
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: ex.isCustom
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _showExerciseDialog(context, ex, workoutProvider),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                      onPressed: () => _showDeleteConfirm(context, ex, workoutProvider),
                                    ),
                                  ],
                                )
                              : const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff2563eb),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showExerciseDialog(context, null, workoutProvider),
      ),
    );
  }

  void _showExerciseDialog(BuildContext context, Exercise? ex, WorkoutProvider provider) {
    final formKey = GlobalKey<FormState>();
    String name = ex?.name ?? '';
    String category = ex?.category ?? 'Pectoraux';
    String notes = ex?.notes ?? '';

    // Standard category presets for easier input
    final categories = ['Pectoraux', 'Dos', 'Jambes', 'Épaules', 'Bras', 'Abdominaux', 'Cardio'];
    if (ex != null && !categories.contains(ex.category)) {
      categories.add(ex.category);
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(ex == null ? "Nouvel Exercice" : "Modifier l'Exercice"),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: name,
                    decoration: const InputDecoration(
                      labelText: "Nom de l'exercice",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? "Requis" : null,
                    onSaved: (val) => name = val!.trim(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: categories.contains(category) ? category : categories.first,
                    decoration: const InputDecoration(
                      labelText: "Catégorie",
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) category = val;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: notes,
                    decoration: const InputDecoration(
                      labelText: "Notes / Description",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                    onSaved: (val) => notes = val?.trim() ?? '',
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
              child: const Text("Enregistrer"),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();
                  if (ex == null) {
                    provider.createCustomExercise(name, category, notes: notes);
                  } else {
                    final updated = Exercise(
                      id: ex.id,
                      name: name,
                      category: category,
                      notes: notes,
                      isCustom: true,
                    );
                    provider.updateExercise(updated);
                  }
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, Exercise ex, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Supprimer l'exercice ?"),
          content: Text("Êtes-vous sûr de vouloir supprimer l'exercice \"${ex.name}\" ?"),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButton(
              child: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
              onPressed: () {
                provider.deleteExercise(ex.id);
                Navigator.pop(ctx);
              },
            ),
          ],
        );
      },
    );
  }
}
