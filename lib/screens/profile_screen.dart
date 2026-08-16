import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/security_utils.dart';
import '../widgets/password_strength_indicator.dart';

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
    // Vérifier l'état de l'email au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkEmailVerified();
    });
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

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogKey = GlobalKey<FormState>();

    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final auth = Provider.of<AuthProvider>(context);
            return AlertDialog(
              backgroundColor: const Color(0xff0f172a),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xff3b82f6), size: 24),
                  SizedBox(width: 10),
                  Text(
                    "Changer le mot de passe",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: obscureCurrent,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: "Mot de passe actuel",
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white60,
                            ),
                            onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Veuillez entrer votre mot de passe actuel." : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: obscureNew,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: _inputDecoration(
                          labelText: "Nouveau mot de passe",
                          prefixIcon: Icons.lock_reset,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white60,
                            ),
                            onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                          ),
                        ),
                        validator: (v) => SecurityUtils.validatePassword(v),
                      ),
                      PasswordStrengthIndicator(password: newPasswordController.text),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscureConfirm,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: "Confirmer le nouveau mot de passe",
                          prefixIcon: Icons.check_circle_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white60,
                            ),
                            onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Veuillez confirmer le mot de passe.";
                          if (v != newPasswordController.text) return "Les mots de passe ne correspondent pas.";
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Annuler", style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (!dialogKey.currentState!.validate()) return;
                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);

                          final ok = await auth.changePassword(
                            currentPasswordController.text,
                            newPasswordController.text,
                          );

                          if (mounted) {
                            if (ok) {
                              nav.pop();
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text("Mot de passe modifié avec succès !"),
                                  backgroundColor: Color(0xff10b981),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(auth.errorMessage ?? "Erreur lors de la modification."),
                                  backgroundColor: const Color(0xffef4444),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Mettre à jour", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showUpdateEmailDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final dialogKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final auth = Provider.of<AuthProvider>(context);
            return AlertDialog(
              backgroundColor: const Color(0xff0f172a),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: const Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: Color(0xff3b82f6), size: 24),
                  SizedBox(width: 10),
                  Text(
                    "Modifier l'adresse email",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: dialogKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Pour votre sécurité, saisissez votre nouvelle adresse email ainsi que votre mot de passe actuel :",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: "Nouvelle adresse email",
                          prefixIcon: Icons.email_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Veuillez entrer une adresse email.";
                          if (!SecurityUtils.isValidEmail(v.trim())) return "Adresse email invalide.";
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: _inputDecoration(
                          labelText: "Mot de passe actuel",
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: Colors.white60,
                            ),
                            onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Veuillez entrer votre mot de passe." : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Annuler", style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          if (!dialogKey.currentState!.validate()) return;
                          final nav = Navigator.of(ctx);
                          final messenger = ScaffoldMessenger.of(context);

                          final ok = await auth.updateEmail(
                            passwordController.text,
                            emailController.text.trim(),
                          );

                          if (mounted) {
                            if (ok) {
                              nav.pop();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Un e-mail de confirmation a été envoyé à ${emailController.text.trim()}. Veuillez valider le lien pour finaliser la mise à jour.",
                                  ),
                                  backgroundColor: const Color(0xff10b981),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(auth.errorMessage ?? "Erreur lors du changement d'email."),
                                  backgroundColor: const Color(0xffef4444),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Enregistrer", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
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
    final isEmailVerified = authProvider.isEmailVerifiedState;

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
                      const SizedBox(height: 8),

                      // Email verification badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isEmailVerified ? const Color(0xff10b981) : const Color(0xfff59e0b)).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isEmailVerified ? const Color(0xff10b981) : const Color(0xfff59e0b),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isEmailVerified ? Icons.verified_user : Icons.warning_amber_rounded,
                              size: 13,
                              color: isEmailVerified ? const Color(0xff10b981) : const Color(0xfff59e0b),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isEmailVerified ? "Email vérifié" : "Email non vérifié",
                              style: TextStyle(
                                color: isEmailVerified ? const Color(0xff10b981) : const Color(0xfff59e0b),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
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

                      // Email field
                      TextFormField(
                        initialValue: user.email,
                        enabled: false,
                        style: const TextStyle(color: Colors.white70),
                        decoration: _inputDecoration(
                          labelText: "Adresse email actuelle",
                          prefixIcon: Icons.email_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Save button if editing profile
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
                  const SizedBox(height: 24),
                ],

                // Sécurité & Compte Section
                const Text(
                  "Sécurité & Compte",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        // Email verification actions if not verified
                        if (!isEmailVerified) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.mark_email_unread_outlined, color: Color(0xfff59e0b)),
                            title: const Text("Email non vérifié", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                            subtitle: const Text("Validez votre compte pour sécuriser vos données.", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            trailing: TextButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      final ok = await authProvider.sendEmailVerification();
                                      if (mounted) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              ok
                                                  ? "E-mail de confirmation envoyé à ${user.email} !"
                                                  : (authProvider.errorMessage ?? "Erreur d'envoi."),
                                            ),
                                            backgroundColor: ok ? const Color(0xff10b981) : const Color(0xffef4444),
                                          ),
                                        );
                                      }
                                    },
                              child: const Text("Renvoyer", style: TextStyle(color: Color(0xff3b82f6), fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const Divider(color: Colors.white12),
                        ],

                        // Modifier l'adresse email
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.alternate_email, color: Color(0xff93c5fd)),
                          title: const Text("Modifier l'adresse email", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text("Changer l'e-mail associé à votre compte", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: _showUpdateEmailDialog,
                        ),
                        const Divider(color: Colors.white12),

                        // Modifier le mot de passe
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.lock_reset_rounded, color: Color(0xffa78bfa)),
                          title: const Text("Modifier le mot de passe", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                          subtitle: const Text("Mettre à jour vos identifiants de connexion", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                          onTap: _showChangePasswordDialog,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

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

