import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../widgets/category_badge.dart';
import '../widgets/youtube_player_dialog.dart';
import '../widgets/share_qr_dialog.dart';
import '../widgets/import_data_dialog.dart';

class ExercisesScreen extends StatefulWidget {
  const ExercisesScreen({super.key});

  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tous';

  bool _isGridView = false;

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
            icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xff2563eb)),
            tooltip: "Importer des exercices (QR / Code)",
            onPressed: () => ImportDataDialog.show(context),
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view, color: const Color(0xff2563eb)),
            tooltip: _isGridView ? "Afficher en liste" : "Afficher en grille (3 colonnes)",
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
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

          // Exercises List / Grid
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child: Text(
                      "Aucun exercice trouvé",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  )
                : _isGridView
                    ? GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.82,
                        ),
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final ex = filteredExercises[index];
                          final mainCat = ex.categories.isNotEmpty ? ex.categories.first : ex.category;
                          final catInfo = CategoryHelper.getInfo(mainCat);

                          return Card(
                            margin: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: catInfo.color.withValues(alpha: 0.3), width: 1),
                            ),
                            color: const Color(0xff1e1e24),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Icon(catInfo.icon, size: 14, color: catInfo.color),
                                      if (ex.videoUrl != null && ex.videoUrl!.trim().isNotEmpty)
                                        GestureDetector(
                                          onTap: () => YoutubePlayerDialog.show(context, ex.name, ex.videoUrl!),
                                          child: const Icon(Icons.play_circle_fill, color: Colors.red, size: 16),
                                        )
                                      else if (ex.isCustom)
                                        PopupMenuButton<String>(
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          icon: const Icon(Icons.more_vert, size: 16, color: Colors.grey),
                                          onSelected: (val) {
                                            if (val == 'edit') {
                                              _showExerciseDialog(context, ex, workoutProvider);
                                            } else if (val == 'delete') {
                                              _showDeleteConfirm(context, ex, workoutProvider);
                                            }
                                          },
                                          itemBuilder: (ctx) => [
                                            const PopupMenuItem(value: 'edit', child: Text("Modifier", style: TextStyle(fontSize: 12))),
                                            const PopupMenuItem(value: 'delete', child: Text("Supprimer", style: TextStyle(fontSize: 12, color: Colors.redAccent))),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    ex.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: catInfo.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      mainCat,
                                      style: TextStyle(fontSize: 9, color: catInfo.color, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),
                            ),
                          );
                        },
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
                                  IconButton(
                                    icon: const Icon(Icons.qr_code_2_rounded, size: 20, color: Color(0xff2563eb)),
                                    tooltip: "Partager cet exercice (QR Code)",
                                    onPressed: () => ShareQrDialog.showForExercise(context, ex),
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
                                  ],
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
