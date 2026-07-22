import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'programs_screen.dart';
import 'history_screen.dart';
import 'active_session_screen.dart';
import 'exercises_screen.dart';
import 'statistics_screen.dart';

import '../widgets/ad_banner_widget.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ProgramsScreen(),
    HistoryScreen(),
    StatisticsScreen(),
    ExercisesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final provider = Provider.of<WorkoutProvider>(context);
    final activeSession = provider.activeSession;
    final isAdmin = authProvider.currentUser?.isAdmin == true;

    return Scaffold(
      body: Column(
        children: [
          if (isAdmin)
            SafeArea(
              bottom: false,
              child: Container(
                color: const Color(0xff1e1b4b), // Dark violet/indigo
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.admin_panel_settings, color: Color(0xffa78bfa), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Mode Entraînement (Admin)",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          "Retour Gestion",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: true,
                          activeThumbColor: const Color(0xffa78bfa),
                          activeTrackColor: const Color(0xff4c1d95),
                          onChanged: (val) {
                            if (!val) {
                              authProvider.setAdminTrainingMode(false);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: Stack(
              children: [
                // Screen contents
                IndexedStack(
                  index: _currentIndex,
                  children: _screens,
                ),
                
                // Persistent floating Active Workout Bar
                if (activeSession != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 8,
                    child: _buildActiveWorkoutBar(context, provider),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AdBannerWidget(),
            Container(
              padding: EdgeInsets.only(bottom: activeSession != null ? 70.0 : 0.0),
              child: BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                onTap: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.dashboard_outlined),
                    activeIcon: Icon(Icons.dashboard),
                    label: "Tableau de bord",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.assignment_outlined),
                    activeIcon: Icon(Icons.assignment),
                    label: "Programmes",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.history_outlined),
                    activeIcon: Icon(Icons.history),
                    label: "Historique",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.show_chart_outlined),
                    activeIcon: Icon(Icons.show_chart),
                    label: "Stats",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.fitness_center_outlined),
                    activeIcon: Icon(Icons.fitness_center),
                    label: "Exercices",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildActiveWorkoutBar(BuildContext context, WorkoutProvider provider) {
    final session = provider.activeSession!;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ActiveSessionScreen()),
        );
      },
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xff2563eb),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.fitness_center, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ValueListenableBuilder<Duration>(
                      valueListenable: provider.sessionDurationNotifier,
                      builder: (context, duration, _) {
                        final String durationString = '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
                        return Text(
                          "Entraînement en cours • $durationString",
                          style: const TextStyle(fontSize: 11, color: Colors.white70),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
