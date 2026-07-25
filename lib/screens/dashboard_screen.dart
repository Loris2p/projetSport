import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import 'active_session_screen.dart';

import '../widgets/workout_calendar_widget.dart';

class DashboardScreen extends StatelessWidget {

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext buildContext) {
    final workoutProvider = Provider.of<WorkoutProvider>(buildContext);
    final authProvider = Provider.of<AuthProvider>(buildContext);

    // Format current date
    final String formattedDate = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    // Capitalize first letter
    final String capitalizedDate = formattedDate.isNotEmpty
        ? formattedDate[0].toUpperCase() + formattedDate.substring(1)
        : '';

    // Calculate volume in tons (using memory cached values)
    final double weeklyVolumeTons = workoutProvider.weeklyVolume / 1000.0;
    final int weeklyWorkouts = workoutProvider.weeklyWorkoutsCount;

    // Get latest program for quick resume shortcut
    final programs = workoutProvider.programs;
    final quickProgram = programs.isNotEmpty ? programs.first : null;

    final userName = authProvider.currentUser?.displayName ?? '';

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        capitalizedDate,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName.isNotEmpty ? "Bonjour, $userName !" : "Bonjour !",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'logout') {
                        await authProvider.signOut();
                        if (buildContext.mounted) {
                          await buildContext.read<WorkoutProvider>().loadUser(null);
                        }
                      } else if (value == 'admin') {
                        authProvider.setAdminTrainingMode(false);
                      }
                    },
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (BuildContext context) => [
                      if (authProvider.currentUser?.isAdmin == true)
                        const PopupMenuItem<String>(
                          value: 'admin',
                          child: Row(
                            children: [
                              Icon(Icons.admin_panel_settings, color: Color(0xff7c3aed), size: 20),
                              SizedBox(width: 8),
                              Text("Administration"),
                            ],
                          ),
                        ),
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Color(0xffef4444), size: 20),
                            SizedBox(width: 8),
                            Text("Déconnexion", style: TextStyle(color: Color(0xffef4444))),
                          ],
                        ),
                      ),
                    ],
                    child: const CircleAvatar(
                      backgroundColor: Color(0xff2563eb),
                      radius: 22,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Weekly Stats Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff1e1e24), Color(0xff121214)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xff2d2d34), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "STATISTIQUES HEBDOMADAIRES (7j)",
                      style: TextStyle(
                        color: Color(0xff2563eb),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.fitness_center,
                          value: "$weeklyWorkouts",
                          label: "Séances",
                        ),
                        _buildStatItem(
                          icon: Icons.insights,
                          value: "${weeklyVolumeTons.toStringAsFixed(2)} T",
                          label: "Volume total",
                        ),
                        _buildStatItem(
                          icon: Icons.local_fire_department,
                          value: "${(weeklyWorkouts * 380)} kcal", // Estimé ou basé sur l'historique
                          label: "Cal. brûlées",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Calendar Card for Retention & Frequency
              const WorkoutCalendarWidget(),

              const SizedBox(height: 30),

              // Quick Actions Title
              const Text(
                "Commencer un entraînement",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),

              // Quick Start Empty Session
              _buildActionCard(
                context: buildContext,
                title: "Nouvelle Séance Vide",
                subtitle: "Démarrer un entraînement libre sans programme pré-défini",
                icon: Icons.add_circle,
                gradientColors: [Color(0xff2563eb), Color(0xff1d4ed8)],
                onTap: () {
                  workoutProvider.startSession(null);
                  Navigator.push(
                    buildContext,
                    MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
                  );
                },
              ),
              const SizedBox(height: 15),

              // Quick Shortcut (Active Session vs Launch Program)
              if (workoutProvider.activeSession != null) ...[
                _buildActionCard(
                  context: buildContext,
                  title: "Continuer : ${workoutProvider.activeSession!.name}",
                  subtitle: "Une séance d'entraînement est actuellement en cours",
                  icon: Icons.play_circle_fill,
                  gradientColors: const [Color(0xff2563eb), Color(0xff1d4ed8)],
                  onTap: () {
                    Navigator.push(
                      buildContext,
                      MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
                    );
                  },
                ),
                const SizedBox(height: 15),
              ] else if (quickProgram != null) ...[
                _buildActionCard(
                  context: buildContext,
                  title: "Lancer : ${quickProgram.name}",
                  subtitle: quickProgram.description.isNotEmpty
                      ? quickProgram.description
                      : "Démarrer rapidement ce programme",
                  icon: Icons.play_arrow_rounded,
                  gradientColors: const [Color(0xff1e1e24), Color(0xff2d2d34)],
                  onTap: () {
                    workoutProvider.startSession(quickProgram);
                    Navigator.push(
                      buildContext,
                      MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
                    );
                  },
                  onSettingsTap: () {
                    _showSelectQuickProgramDialog(buildContext, workoutProvider);
                  },
                ),
                const SizedBox(height: 15),
              ],

              // Tip Card (Inspirational / Ergonomic tip)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xff1e1e24),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xff2d2d34)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.tips_and_updates, color: Colors.amber, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Conseil d'entraînement",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Complétez chaque série en cochant la case. Le chronomètre de repos se lancera automatiquement.",
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[400], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    VoidCallback? onSettingsTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xff2d2d34), width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
            if (onSettingsTap != null) ...[
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.push_pin_outlined, color: Colors.white70, size: 20),
                tooltip: "Changer le programme en raccourci",
                onPressed: onSettingsTap,
              ),
            ],
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSelectQuickProgramDialog(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Programme en raccourci"),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Choisissez quel programme afficher sur l'écran d'accueil pour un lancement rapide :",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...provider.programs.map((prog) {
                    final isCurrent = provider.quickProgram?.id == prog.id;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        isCurrent ? Icons.push_pin : Icons.push_pin_outlined,
                        color: isCurrent ? const Color(0xff2563eb) : Colors.grey,
                      ),
                      title: Text(prog.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: prog.description.isNotEmpty ? Text(prog.description, maxLines: 1) : null,
                      trailing: isCurrent ? const Icon(Icons.check_circle, color: Color(0xff2563eb)) : null,
                      onTap: () {
                        provider.setFavoriteProgramId(prog.id);
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Fermer"),
            ),
          ],
        );
      },
    );
  }
}
