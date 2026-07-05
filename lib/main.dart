import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme.dart';
import 'providers/workout_provider.dart';
import 'providers/auth_provider.dart';
import 'repositories/localstore_workout_repository.dart';
import 'repositories/auth_repository.dart';
import 'services/health_sync_service.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize locale formatting for French (used for dates and histories)
  await initializeDateFormatting('fr_FR', null);

  // Set up repository and sync services
  final authRepository = LocalMockAuthRepository();
  final workoutRepository = LocalstoreWorkoutRepository();
  // STANDBY : Utilisation de MockHealthSyncService au lieu de FlutterHealthSyncService pour le développement local
  final healthSyncService = MockHealthSyncService();

  final authProvider = AuthProvider(authRepository: authRepository);
  final workoutProvider = WorkoutProvider(
    repository: workoutRepository,
    healthSyncService: healthSyncService,
  );

  // Pre-load data from local storage
  await authProvider.init();
  final currentUid = authProvider.currentUser?.uid;
  await workoutProvider.loadUser(currentUid);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
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
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'SportApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authProvider.isAuthenticated ? const MainShell() : const LoginScreen(),
    );
  }
}

