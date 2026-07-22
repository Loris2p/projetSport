import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/workout_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLoginMode = true;
  bool _obscurePassword = true;

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
    _nameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      context.read<AuthProvider>().clearError();
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final email = _emailController.text;
    final password = _passwordController.text;
    final name = _nameController.text;

    bool success;
    if (_isLoginMode) {
      success = await authProvider.signIn(email, password);
    } else {
      success = await authProvider.signUp(email, password, name);
    }

    if (success && mounted) {
      final userId = authProvider.currentUser?.uid;
      final workoutProvider = context.read<WorkoutProvider>();
      final messenger = ScaffoldMessenger.of(context);
      
      await workoutProvider.loadUser(userId);

      messenger.showSnackBar(
        SnackBar(
          content: Text(_isLoginMode ? "Bienvenue !" : "Compte créé avec succès !"),
          backgroundColor: const Color(0xff10b981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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

                            // Name field (Sign Up only)
                            if (!_isLoginMode) ...[
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  labelText: "Nom complet",
                                  prefixIcon: Icons.person_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Veuillez entrer votre nom.";
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
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration(
                                labelText: "Adresse email",
                                prefixIcon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Veuillez entrer votre email.";
                                }
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                                  return "Veuillez entrer un email valide.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
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
                                if (value.length < 6) {
                                  return "Le mot de passe doit faire au moins 6 caractères.";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Submit Button
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xff2563eb), Color(0xff7c3aed)], // Blue to Purple gradient
                                ),
                                boxShadow: [
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
                                onPressed: authProvider.isLoading ? null : _submit,
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
                                        _isLoginMode ? "Se connecter" : "S'enregistrer",
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
        borderSide: const BorderSide(color: Color(0xff3b82f6), width: 1.5), // Electric Blue glow on focus
      ),
    );
  }
}
