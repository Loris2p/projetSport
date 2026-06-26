import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme.dart';
import 'providers/workout_provider.dart';
import 'repositories/workout_repository.dart';
import 'services/health_sync_service.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize locale formatting for French (used for dates and histories)
  await initializeDateFormatting('fr_FR', null);

  // Set up repository and sync services
  final workoutRepository = LocalJsonWorkoutRepository();
  final healthSyncService = FlutterHealthSyncService(); // Use real integration (falls back gracefully)

  final workoutProvider = WorkoutProvider(
    repository: workoutRepository,
    healthSyncService: healthSyncService,
  );

  // Pre-load data from files
  await workoutProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<WorkoutProvider>.value(value: workoutProvider),
      ],
      child: const SportApp(),
    ),
  );
}

class SportApp extends StatelessWidget {
  const SportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SportApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainShell(),
    );
  }
}
