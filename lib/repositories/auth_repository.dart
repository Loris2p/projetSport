import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<void> init();
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> signIn(String email, String password);
  Future<UserProfile> signUp(String email, String password, String name);
  Future<void> signOut();
  Future<List<UserProfile>> getAllUsers();
  Future<void> deleteUser(String uid);
  Future<void> updateUser(UserProfile user);
}

class LocalMockAuthRepository implements AuthRepository {
  UserProfile? _currentUser;
  final _uuid = const Uuid();

  // Base de données en mémoire pour simuler les comptes sans stockage physique
  final Map<String, Map<String, dynamic>> _mockUsers = {};

  @override
  Future<void> init() async {
    // Aucune donnée hardcodée dans le code.
  }

  // Hachage du mot de passe en SHA-256 pour éviter d'avoir du texte brut en mémoire
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    // Simuler un délai réseau
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception("L'email et le mot de passe ne peuvent pas être vides.");
    }

    if (password.length < 6) {
      throw Exception("Le mot de passe doit contenir au moins 6 caractères.");
    }

    // Récupérer les identifiants administrateur du .env
    final adminEmail = dotenv.env['ADMIN_EMAIL']?.trim();
    final adminPassword = dotenv.env['ADMIN_PASSWORD'];

    if (adminEmail == null || adminPassword == null) {
      throw Exception("Erreur de configuration : identifiants administrateurs manquants dans le fichier d'environnement.");
    }

    // Vérifier si c'est l'administrateur
    if (email.trim().toLowerCase() == adminEmail.toLowerCase()) {
      if (password == adminPassword) {
        _currentUser = UserProfile(
          uid: 'admin_uid_global',
          email: adminEmail,
          displayName: 'Administrateur',
          isAdmin: true,
        );
        return _currentUser!;
      } else {
        throw Exception("Mot de passe incorrect pour l'administrateur.");
      }
    }

    // Vérifier dans la base de données en mémoire avec comparaison du mot de passe haché
    final String hashedPassword = _hashPassword(password);
    UserProfile? foundUser;
    for (var userData in _mockUsers.values) {
      if (userData['email'] == email.trim().toLowerCase()) {
        if (userData['password'] == hashedPassword) {
          foundUser = UserProfile.fromJson(userData);
        } else {
          throw Exception("Mot de passe incorrect.");
        }
        break;
      }
    }

    if (foundUser == null) {
      throw Exception("Aucun utilisateur trouvé avec cet email. Veuillez créer un compte.");
    }

    _currentUser = foundUser;
    return _currentUser!;
  }

  @override
  Future<UserProfile> signUp(String email, String password, String name) async {
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.trim().isEmpty || password.trim().isEmpty || name.trim().isEmpty) {
      throw Exception("Tous les champs sont obligatoires.");
    }

    if (password.length < 6) {
      throw Exception("Le mot de passe doit contenir au moins 6 caractères.");
    }

    // Récupérer les identifiants administrateur du .env
    final adminEmail = dotenv.env['ADMIN_EMAIL']?.trim();
    if (adminEmail == null) {
      throw Exception("Erreur de configuration : email de l'administrateur manquant dans le fichier d'environnement.");
    }
    if (email.trim().toLowerCase() == adminEmail.toLowerCase()) {
      throw Exception("Cet email est réservé à l'administrateur.");
    }

    // Vérifier si l'utilisateur existe déjà
    for (var userData in _mockUsers.values) {
      if (userData['email'] == email.trim().toLowerCase()) {
        throw Exception("Cet email est déjà utilisé par un autre compte.");
      }
    }

    final uid = _uuid.v4();
    final newProfile = UserProfile(
      uid: uid,
      email: email.trim().toLowerCase(),
      displayName: name.trim(),
      isAdmin: false, // Inscription standard -> JAMAIS admin
    );

    // Stocker dans la base en mémoire avec hachage du mot de passe
    final dbData = newProfile.toJson();
    dbData['password'] = _hashPassword(password);
    _mockUsers[uid] = dbData;
    
    _currentUser = newProfile;
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }

  @override
  Future<List<UserProfile>> getAllUsers() async {
    return _mockUsers.values
        .map((u) => UserProfile.fromJson(u))
        .toList();
  }

  @override
  Future<void> deleteUser(String uid) async {
    _mockUsers.remove(uid);
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    final existingData = _mockUsers[user.uid];
    if (existingData != null) {
      final dbData = user.toJson();
      dbData['password'] = existingData['password']; // conserver le mot de passe
      _mockUsers[user.uid] = dbData;
    }

    // Si on met à jour le profil de l'utilisateur actuellement connecté
    if (_currentUser?.uid == user.uid) {
      _currentUser = user;
    }
  }
}
