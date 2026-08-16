import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/security_utils.dart';
import '../widgets/password_strength_indicator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();

  DateTime? _birthDate;
  bool _isLoginMode = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _birthDate = null;
      _birthDateController.clear();
      _confirmPasswordController.clear();
      context.read<AuthProvider>().clearError();
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime initialDate = _birthDate ?? DateTime(2000, 1, 1);
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
        _birthDate = picked;
        _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    bool success;
    if (_isLoginMode) {
      success = await authProvider.signIn(email, password);
    } else {
      success = await authProvider.signUp(
        email,
        password,
        name,
        birthDate: _birthDate,
      );
    }

    if (success && mounted) {
      TextInput.finishAutofillContext();
      final userId = authProvider.currentUser?.uid;
      final workoutProvider = context.read<WorkoutProvider>();
      final messenger = ScaffoldMessenger.of(context);
      
      await workoutProvider.loadUser(userId);

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isLoginMode
                ? "Bienvenue !"
                : "Compte créé avec succès ! Un e-mail de confirmation vous a été envoyé.",
          ),
          backgroundColor: const Color(0xff10b981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showForgotPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    final dialogFormKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        final auth = Provider.of<AuthProvider>(ctx);
        return AlertDialog(
          backgroundColor: const Color(0xff0f172a),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xff3b82f6), size: 24),
              SizedBox(width: 10),
              Text(
                "Mot de passe oublié",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Form(
            key: dialogFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Saisissez votre adresse email pour recevoir un lien sécurisé de réinitialisation :",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: "Adresse email",
                    prefixIcon: Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Veuillez saisir votre adresse email.";
                    }
                    if (!SecurityUtils.isValidEmail(value.trim())) {
                      return "Veuillez saisir un email valide.";
                    }
                    return null;
                  },
                ),
              ],
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
                      if (!dialogFormKey.currentState!.validate()) return;
                      final email = resetEmailController.text.trim();
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(ctx);

                      final ok = await auth.sendPasswordResetEmail(email);
                      if (mounted) {
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? "Si un compte est associé à $email, un e-mail de réinitialisation vous a été envoyé."
                                  : (auth.errorMessage ?? "Erreur lors de l'envoi."),
                            ),
                            backgroundColor: ok ? const Color(0xff10b981) : const Color(0xffef4444),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: auth.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text("Envoyer le lien", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLocked = authProvider.isLockedOut;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff090d16), // Dark Slate/Black
              Color(0xff0f172a), // Slate 900
              Color(0xff1e1b4b), // Deep Indigo
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Icon with glowing background effect
                      Center(
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xff3b82f6), Color(0xff8b5cf6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xff8b5cf6).withValues(alpha: 0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // App Name
                      const Center(
                        child: Text(
                          "SPORTILIFE",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          "Dépassez vos limites, suivez vos progrès",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Main card with glassmorphic style
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _fadeAnimation,
                            child: SlideTransition(
                              position: _slideAnimation,
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _isLoginMode ? "Connexion" : "Créer un compte",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Display Error Message if exists
                              if (authProvider.errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffef4444).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xffef4444).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Color(0xfff87171), size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          authProvider.errorMessage!,
                                          style: const TextStyle(color: Color(0xfff87171), fontSize: 13),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Name & Birth Date fields (Sign Up only)
                              if (!_isLoginMode) ...[
                                TextFormField(
                                  controller: _nameController,
                                  keyboardType: TextInputType.name,
                                  autofillHints: const [AutofillHints.name],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    labelText: "Pseudonyme",
                                    prefixIcon: Icons.person_outline,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Veuillez entrer votre pseudonyme.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _birthDateController,
                                  readOnly: true,
                                  style: const TextStyle(color: Colors.white),
                                  onTap: () => _selectBirthDate(context),
                                  decoration: _inputDecoration(
                                    labelText: "Date de naissance",
                                    prefixIcon: Icons.cake_outlined,
                                    suffixIcon: const Icon(Icons.calendar_today, color: Colors.white60, size: 20),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return "Veuillez sélectionner votre date de naissance.";
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email Field
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email, AutofillHints.username],
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  labelText: "Adresse email",
                                  prefixIcon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Veuillez entrer votre email.";
                                  }
                                  if (!SecurityUtils.isValidEmail(value.trim())) {
                                    return "Veuillez entrer une adresse email valide.";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                keyboardType: TextInputType.visiblePassword,
                                autofillHints: _isLoginMode
                                    ? const [AutofillHints.password]
                                    : const [AutofillHints.newPassword],
                                style: const TextStyle(color: Colors.white),
                                onChanged: (_) {
                                  if (!_isLoginMode) {
                                    setState(() {}); // Rafraîchir l'indicateur de force
                                  }
                                },
                                decoration: _inputDecoration(
                                  labelText: "Mot de passe",
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      color: Colors.white60,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Veuillez entrer votre mot de passe.";
                                  }
                                  if (!_isLoginMode) {
                                    return SecurityUtils.validatePassword(value);
                                  }
                                  return null;
                                },
                              ),

                              // Indicateur de force en mode inscription
                              if (!_isLoginMode) ...[
                                PasswordStrengthIndicator(password: _passwordController.text),
                                const SizedBox(height: 16),

                                // Confirm Password Field
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  keyboardType: TextInputType.visiblePassword,
                                  autofillHints: const [AutofillHints.password],
                                  style: const TextStyle(color: Colors.white),
                                  decoration: _inputDecoration(
                                    labelText: "Confirmer le mot de passe",
                                    prefixIcon: Icons.lock_clock_outlined,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white60,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword = !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return "Veuillez confirmer votre mot de passe.";
                                    }
                                    if (value != _passwordController.text) {
                                      return "Les mots de passe ne correspondent pas.";
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              // Mot de passe oublié (Mode connexion)
                              if (_isLoginMode) ...[
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: authProvider.isLoading ? null : _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "Mot de passe oublié ?",
                                      style: TextStyle(
                                        color: Color(0xff93c5fd),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 20),

                              // Submit Button
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: isLocked
                                      ? const LinearGradient(
                                          colors: [Color(0xff475569), Color(0xff334155)],
                                        )
                                      : const LinearGradient(
                                          colors: [Color(0xff2563eb), Color(0xff7c3aed)],
                                        ),
                                  boxShadow: isLocked
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: const Color(0xff2563eb).withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: (authProvider.isLoading || isLocked) ? null : _submit,
                                  child: authProvider.isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          isLocked
                                              ? "Bloqué (${authProvider.remainingLockoutSeconds}s)"
                                              : (_isLoginMode ? "Se connecter" : "S'enregistrer"),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Toggle mode button
                      TextButton(
                        onPressed: authProvider.isLoading ? null : _toggleMode,
                        child: Text(
                          _isLoginMode
                              ? "Vous n'avez pas de compte ? S'inscrire"
                              : "Vous avez déjà un compte ? Se connecter",
                          style: const TextStyle(
                            color: Color(0xffa78bfa), // Light violet
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white60, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.white60, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.04),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      errorStyle: const TextStyle(color: Color(0xfff87171)),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xfff87171), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: const Color(0xfff87171).withValues(alpha: 0.5), width: 1),
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
