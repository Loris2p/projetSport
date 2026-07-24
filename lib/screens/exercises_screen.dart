import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../widgets/category_badge.dart';
import '../widgets/youtube_player_dialog.dart';

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
      final matchesCategory = _selectedCategory == 'Tous' ||
          ex.categories.contains(_selectedCategory) ||
          ex.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Get unique categories for filtering
    final filterCategories = ['Tous', ...CategoryHelper.allCategoryNames];

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
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
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

          // Horizontal Category Filter Chips
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filterCategories.length,
              itemBuilder: (context, idx) {
                final cat = filterCategories[idx];
                final isSelected = _selectedCategory == cat;
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
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

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
                              const SizedBox(height: 6),
                              MultiCategoryBadges(categories: ex.categories, compact: true),
                              if (ex.notes != null && ex.notes!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  ex.notes!,
                                  style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (ex.videoUrl != null && ex.videoUrl!.trim().isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.play_circle_fill, color: Colors.red, size: 24),
                                  tooltip: "Voir la vidéo d'explication",
                                  onPressed: () => YoutubePlayerDialog.show(context, ex.name, ex.videoUrl!),
                                ),
                              if (ex.isCustom) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20),
                                  onPressed: () => _showExerciseDialog(context, ex, workoutProvider),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                  onPressed: () => _showDeleteConfirm(context, ex, workoutProvider),
                                ),
                              ] else if (ex.videoUrl == null || ex.videoUrl!.trim().isEmpty)
                                const Icon(Icons.lock_outline, size: 18, color: Colors.grey),
                            ],
                          ),
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
    List<String> selectedCategories = ex != null ? List.from(ex.categories) : [];

    String notes = ex?.notes ?? '';
    String videoUrl = ex?.videoUrl ?? '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(ex == null ? "Nouvel Exercice" : "Modifier l'Exercice"),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: name,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: "Nom de l'exercice",
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => val == null || val.trim().isEmpty ? "Requis" : null,
                        onSaved: (val) {
                          final trimmed = val!.trim();
                          if (trimmed.isNotEmpty) {
                            name = trimmed[0].toUpperCase() + trimmed.substring(1);
                          } else {
                            name = trimmed;
                          }
                        },
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        "Catégorie(s) musculaire(s) :",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
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
                        initialValue: notes,
                        decoration: const InputDecoration(
                          labelText: "Notes / Description (optionnel)",
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onSaved: (val) => notes = val?.trim() ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        initialValue: videoUrl,
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
                  child: const Text("Enregistrer"),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final cleanNotes = notes.trim().isEmpty ? null : notes.trim();
                      final cleanVideoUrl = videoUrl.trim().isEmpty ? null : videoUrl.trim();
                      if (ex == null) {
                        provider.createCustomExercise(
                          name,
                          categories: selectedCategories,
                          notes: cleanNotes,
                          videoUrl: cleanVideoUrl,
                        );
                      } else {
                        final updated = Exercise(
                          id: ex.id,
                          name: name,
                          categories: selectedCategories,
                          notes: cleanNotes,
                          videoUrl: cleanVideoUrl,
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Supprimer", style: TextStyle(color: Colors.white)),
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
