import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _birthDateController;
  DateTime? _selectedBirthDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final currentUser = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: currentUser?.displayName ?? '');
    _selectedBirthDate = currentUser?.birthDate;
    _birthDateController = TextEditingController(
      text: _selectedBirthDate != null ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  int? _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return null;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    if (!_isEditing) return;

    final DateTime initialDate = _selectedBirthDate ?? DateTime(2000, 1, 1);
    final DateTime firstDate = DateTime(1900);
    final DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xff3b82f6),
              onPrimary: Colors.white,
              surface: Color(0xff1e1b4b),
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: Color(0xff0f172a)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      displayName: _nameController.text.trim(),
      birthDate: _selectedBirthDate,
    );

    final messenger = ScaffoldMessenger.of(context);
    final success = await authProvider.updateUser(updatedUser);

    if (success && mounted) {
      setState(() {
        _isEditing = false;
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Profil mis à jour avec succès !"),
          backgroundColor: Color(0xff10b981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Mon Profil")),
        body: const Center(child: Text("Aucun utilisateur connecté.")),
      );
    }

    final age = _calculateAge(_selectedBirthDate);
    final totalWorkouts = workoutProvider.history.length;

    return Scaffold(
      backgroundColor: const Color(0xff090d16),
      appBar: AppBar(
        backgroundColor: const Color(0xff0f172a),
        elevation: 0,
        title: const Text(
          "Mon Profil",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel_outlined : Icons.edit_outlined),
            tooltip: _isEditing ? "Annuler l'édition" : "Modifier le profil",
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  _nameController.text = user.displayName;
                  _selectedBirthDate = user.birthDate;
                  _birthDateController.text = _selectedBirthDate != null
                      ? DateFormat('dd/MM/yyyy').format(_selectedBirthDate!)
                      : '';
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Profile Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff1e1b4b), Color(0xff0f172a)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: const Color(0xff3b82f6),
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
                        ),
                      ),
                      if (user.isAdmin) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff7c3aed).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xffa78bfa)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.admin_panel_settings, color: Color(0xffa78bfa), size: 14),
                              SizedBox(width: 4),
                              Text(
                                "Administrateur",
                                style: TextStyle(
                                  color: Color(0xffa78bfa),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Activity Summary
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.fitness_center,
                        label: "Séances terminées",
                        value: "$totalWorkouts",
                        color: const Color(0xff3b82f6),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        icon: Icons.cake,
                        label: "Âge",
                        value: age != null ? "$age ans" : "Non renseigné",
                        color: const Color(0xff8b5cf6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Informations personnelles Section
                const Text(
                  "Informations personnelles",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    children: [
                      // Pseudonyme field
                      TextFormField(
                        controller: _nameController,
                        enabled: _isEditing,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: "Pseudonyme",
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return "Veuillez entrer un pseudonyme.";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date de naissance field
                      TextFormField(
                        controller: _birthDateController,
                        readOnly: true,
                        enabled: _isEditing,
                        onTap: () => _selectBirthDate(context),
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: "Date de naissance",
                          prefixIcon: Icons.cake_outlined,
                          suffixIcon: _isEditing
                              ? const Icon(Icons.calendar_today, color: Colors.white60, size: 20)
                              : null,
                          helperText: age != null ? "Âge actuel : $age ans" : "Non renseignée",
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Email field (Always read-only)
                      TextFormField(
                        initialValue: user.email,
                        enabled: false,
                        style: const TextStyle(color: Colors.white70),
                        decoration: _inputDecoration(
                          labelText: "Adresse email (Non modifiable)",
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save button if editing
                if (_isEditing) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563eb),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: authProvider.isLoading ? null : _saveProfile,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "Enregistrer les modifications",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Administration shortcut button if Admin
                if (user.isAdmin) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xff7c3aed)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.admin_panel_settings, color: Color(0xffa78bfa)),
                    label: const Text(
                      "Panneau d'administration",
                      style: TextStyle(color: Color(0xffa78bfa), fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AdminScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Sign out button
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Color(0xffef4444)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Color(0xffef4444)),
                  label: const Text(
                    "Se déconnecter",
                    style: TextStyle(color: Color(0xffef4444), fontWeight: FontWeight.bold),
                  ),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final workoutProvider = context.read<WorkoutProvider>();
                    await authProvider.signOut();
                    await workoutProvider.loadUser(null);
                    if (mounted) {
                      nav.pop();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: labelText,
      helperText: helperText,
      helperStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.white60, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xff3b82f6), width: 1.5),
      ),
    );
  }
}
