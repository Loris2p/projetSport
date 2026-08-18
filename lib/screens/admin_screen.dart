import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../models/exercise.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../widgets/category_badge.dart';
import '../widgets/youtube_player_dialog.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<UserProfile> _users = [];
  bool _isLoadingUsers = true;
  String _userSearchQuery = '';
  String _exerciseSearchQuery = '';
  String _selectedExerciseCategory = 'Tous';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    final authProvider = context.read<AuthProvider>();
    final users = await authProvider.getAllUsers();
    setState(() {
      _users = users;
      _isLoadingUsers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Administration"),
        actions: [
          Row(
            children: [
              const Text(
                "Mode Entraînement",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
              Switch(
                value: authProvider.isAdminTrainingMode,
                activeThumbColor: const Color(0xff2563eb),
                onChanged: (val) {
                  authProvider.setAdminTrainingMode(val);
                },
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xffef4444)),
            tooltip: "Déconnexion",
            onPressed: () async {
              final workoutProvider = context.read<WorkoutProvider>();
              final navigator = Navigator.of(context);

              await authProvider.signOut();
              await workoutProvider.loadUser(null);

              if (navigator.canPop()) {
                navigator.pop();
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xff2563eb),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: "Utilisateurs"),
            Tab(icon: Icon(Icons.fitness_center), text: "Exercices"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersTab(),
          _buildExercisesTab(),
        ],
      ),
    );
  }

  // ==================== ONGLET UTILISATEURS ====================

  Widget _buildUsersTab() {
    if (_isLoadingUsers) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff2563eb)),
        ),
      );
    }

    final filteredUsers = _users.where((user) {
      final matchesSearch = user.displayName.toLowerCase().contains(_userSearchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_userSearchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: "Rechercher un utilisateur...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 8),
              fillColor: Color(0xff1e1e24),
              filled: true,
            ),
            onChanged: (val) {
              setState(() {
                _userSearchQuery = val;
              });
            },
          ),
        ),

        // List
        Expanded(
          child: filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    "Aucun utilisateur trouvé",
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final isCurrentUser = context.read<AuthProvider>().currentUser?.uid == user.uid;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isCurrentUser ? const Color(0xff2563eb).withValues(alpha: 0.4) : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: user.isAdmin ? const Color(0xff7c3aed) : Colors.grey[800],
                          child: Icon(
                            user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                            color: Colors.white,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                user.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (user.isAdmin)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xff7c3aed).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "Admin",
                                  style: TextStyle(fontSize: 10, color: Color(0xffa78bfa), fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showUserEditDialog(user),
                            ),
                            if (!isCurrentUser)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _showUserDeleteConfirm(user),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showUserEditDialog(UserProfile user) {
    final formKey = GlobalKey<FormState>();
    String name = user.displayName;
    bool isAdmin = user.isAdmin;
    bool showAds = user.showAds;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Modifier l'utilisateur"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: name,
                      decoration: const InputDecoration(
                        labelText: "Nom d'affichage",
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? "Requis" : null,
                      onSaved: (val) => name = val!.trim(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text("Rôle Administrateur"),
                      subtitle: const Text("Donner accès aux fonctions admin"),
                      value: isAdmin,
                      activeThumbColor: const Color(0xff7c3aed),
                      onChanged: (val) {
                        setDialogState(() {
                          isAdmin = val;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text("Publicités actives"),
                      subtitle: const Text("Afficher les bannières publicitaires"),
                      value: showAds,
                      activeThumbColor: const Color(0xff2563eb),
                      onChanged: (val) {
                        setDialogState(() {
                          showAds = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Annuler"),
                  onPressed: () => Navigator.pop(ctx),
                ),
                ElevatedButton(
                  child: const Text("Enregistrer"),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final updated = user.copyWith(
                        displayName: name,
                        isAdmin: isAdmin,
                        showAds: showAds,
                      );
                      
                      final authProvider = context.read<AuthProvider>();
                      final navigator = Navigator.of(ctx);
                      final success = await authProvider.updateUser(updated);
                      if (success) {
                        navigator.pop();
                        _loadUsers();
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

  void _showUserDeleteConfirm(UserProfile user) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Supprimer l'utilisateur ?"),
          content: Text("Êtes-vous sûr de vouloir supprimer définitivement l'utilisateur \"${user.displayName}\" (${user.email}) ?Cette action est irréversible."),
          actions: [
            TextButton(
              child: const Text("Annuler"),
              onPressed: () => Navigator.pop(ctx),
            ),
            TextButton(
              child: const Text("Supprimer", style: TextStyle(color: Colors.redAccent)),
              onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                final navigator = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                final success = await authProvider.deleteUser(user.uid);
                if (success && mounted) {
                  navigator.pop();
                  _loadUsers();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text("Utilisateur supprimé."),
                      backgroundColor: Color(0xffef4444),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // ==================== ONGLET EXERCICES ====================

  Widget _buildExercisesTab() {
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final allExercises = workoutProvider.exercises;

    final filteredExercises = allExercises.where((ex) {
      final query = _exerciseSearchQuery.toLowerCase();
      final matchesSearch = ex.name.toLowerCase().contains(query) ||
          (ex.equipment != null && ex.equipment!.toLowerCase().contains(query));
      final matchesCategory = _selectedExerciseCategory == 'Tous' ||
          ex.categories.contains(_selectedExerciseCategory) ||
          ex.category == _selectedExerciseCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    final filterCategories = ['Tous', ...CategoryHelper.allCategoryNames];

    return Column(
      children: [
        // Search & Filter header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: "Rechercher un exercice, une machine...",
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  fillColor: Color(0xff1e1e24),
                  filled: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _exerciseSearchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterCategories.length,
                  itemBuilder: (context, idx) {
                    final cat = filterCategories[idx];
                    final isSelected = _selectedExerciseCategory == cat;
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
                            _selectedExerciseCategory = cat;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // List
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
                        leading: const CircleAvatar(
                          backgroundColor: Colors.white10,
                          child: Icon(Icons.fitness_center, color: Color(0xff2563eb)),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ex.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: ex.isCustom
                                    ? const Color(0xff2563eb).withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ex.isCustom ? "Privé" : "Public",
                                style: TextStyle(
                                  fontSize: 9,
                                  color: ex.isCustom ? const Color(0xff2563eb) : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                MultiCategoryBadges(categories: ex.categories, compact: true),
                                if (ex.equipment != null && ex.equipment!.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.white12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.fitness_center_outlined, size: 11, color: Colors.white70),
                                        const SizedBox(width: 4),
                                        Text(
                                          ex.equipment!,
                                          style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
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
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showExerciseDialog(ex, workoutProvider),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              onPressed: () => _showExerciseDeleteConfirm(ex, workoutProvider),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // FAB to add new exercise
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text("Créer un exercice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () => _showExerciseDialog(null, workoutProvider),
            ),
          ),
        ),
      ],
    );
  }

  void _showExerciseDialog(Exercise? ex, WorkoutProvider provider) {
    final formKey = GlobalKey<FormState>();
    String name = ex?.name ?? '';
    List<String> selectedCategories = ex != null ? List.from(ex.categories) : [];
    String equipment = ex?.equipment ?? '';
    String notes = ex?.notes ?? '';
    String videoUrl = ex?.videoUrl ?? '';
    bool isCustom = ex?.isCustom ?? false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(ex == null ? "Créer un Exercice (Admin)" : "Modifier l'Exercice (Admin)"),
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
                          name = trimmed.isNotEmpty ? (trimmed[0].toUpperCase() + trimmed.substring(1)) : trimmed;
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
                        initialValue: equipment,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: "Machine / Matériel requis (optionnel)",
                          hintText: "Ex: Barre guidée, Haltères, Poulie vis-à-vis...",
                          prefixIcon: Icon(Icons.fitness_center_outlined),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (val) => equipment = val?.trim() ?? '',
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
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text("Exercice privé (personnalisé)"),
                        subtitle: const Text("Si désactivé, l'exercice sera 'Public' (visible par tous)"),
                        value: isCustom,
                        activeThumbColor: const Color(0xff2563eb),
                        onChanged: (val) {
                          setDialogState(() {
                            isCustom = val;
                          });
                        },
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
                      final cleanEquipment = equipment.trim().isEmpty ? null : equipment.trim();
                      final cleanNotes = notes.trim().isEmpty ? null : notes.trim();
                      final cleanVideoUrl = videoUrl.trim().isEmpty ? null : videoUrl.trim();
                      if (ex == null) {
                        final newEx = Exercise(
                          id: 'exercise_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          categories: selectedCategories,
                          equipment: cleanEquipment,
                          notes: cleanNotes,
                          videoUrl: cleanVideoUrl,
                          isCustom: isCustom,
                        );
                        provider.updateExercise(newEx);
                      } else {
                        final updated = Exercise(
                          id: ex.id,
                          name: name,
                          categories: selectedCategories,
                          equipment: cleanEquipment,
                          notes: cleanNotes,
                          videoUrl: cleanVideoUrl,
                          isCustom: isCustom,
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

  void _showExerciseDeleteConfirm(Exercise ex, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Supprimer l'exercice ?"),
          content: Text("Êtes-vous sûr de vouloir supprimer l'exercice \"${ex.name}\" ?Cette suppression sera répercutée pour tous les utilisateurs."),
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
