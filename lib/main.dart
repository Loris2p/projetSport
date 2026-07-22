import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firedart/firedart.dart' as fd;
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'providers/workout_provider.dart';
import 'providers/auth_provider.dart';
import 'repositories/firebase_auth_repository.dart';
import 'repositories/firestore_workout_repository.dart';
import 'services/ad_service.dart';
import 'services/health_sync_service.dart';
import 'services/prefs_token_store.dart';
import 'screens/main_shell.dart';
import 'screens/login_screen.dart';
import 'screens/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await AdService.initialize();

  
  // Initialisation hybride Firebase
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
    final prefs = await SharedPreferences.getInstance();
    fd.FirebaseAuth.initialize(
      DefaultFirebaseOptions.windows.apiKey, 
      PrefsTokenStore(prefs)
    );
    fd.Firestore.initialize(DefaultFirebaseOptions.windows.projectId);
  } else {
    // Initialize Firebase using official SDK
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Initialize locale formatting for French (used for dates and histories)
  await initializeDateFormatting('fr_FR', null);

  // Set up repository and sync services
  final authRepository = FirebaseAuthRepository();
  final workoutRepository = FirestoreWorkoutRepository();

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
      title: 'SportiLife',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authProvider.isAuthenticated
          ? (authProvider.currentUser?.isAdmin == true
              ? (authProvider.isAdminTrainingMode ? const MainShell() : const AdminScreen())
              : const MainShell())
          : const LoginScreen(),
    );
  }
}

