import 'package:localstore/localstore.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<void> init();
  Future<UserProfile?> getCurrentUser();
  Future<UserProfile> signIn(String email, String password);
  Future<UserProfile> signUp(String email, String password, String name);
  Future<void> signOut();
}

class LocalMockAuthRepository implements AuthRepository {
  final _db = Localstore.instance;
  UserProfile? _currentUser;
  final _uuid = const Uuid();

  @override
  Future<void> init() async {
    try {
      final sessionData = await _db.collection('auth').doc('session').get();
      if (sessionData != null) {
        _currentUser = UserProfile.fromJson(sessionData);
      }
    } catch (e) {
      _currentUser = null;
    }
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

    // Récupérer tous les utilisateurs pour voir si l'email existe
    final usersMap = await _db.collection('users').get();
    UserProfile? foundUser;

    if (usersMap != null) {
      for (var entry in usersMap.entries) {
        final userData = entry.value as Map<String, dynamic>;
        if (userData['email'] == email.trim().toLowerCase()) {
          // Vérification fictive du mot de passe (on vérifie s'il correspond au mot de passe stocké ou on accepte tout pour le mock)
          // On va stocker le mot de passe dans le mock pour simuler une vraie authentification
          if (userData['password'] == password) {
            foundUser = UserProfile.fromJson(userData);
          } else {
            throw Exception("Mot de passe incorrect.");
          }
          break;
        }
      }
    }

    if (foundUser == null) {
      // Pour rendre le mock convivial, si aucun utilisateur n'existe du tout dans la BDD,
      // ou si on veut permettre une connexion facile, on peut jeter une erreur
      throw Exception("Aucun utilisateur trouvé avec cet email. Veuillez créer un compte.");
    }

    _currentUser = foundUser;
    // Sauvegarder la session active
    await _db.collection('auth').doc('session').set(_currentUser!.toJson());
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

    // Vérifier si l'utilisateur existe déjà
    final usersMap = await _db.collection('users').get();
    if (usersMap != null) {
      for (var entry in usersMap.entries) {
        final userData = entry.value as Map<String, dynamic>;
        if (userData['email'] == email.trim().toLowerCase()) {
          throw Exception("Cet email est déjà utilisé par un autre compte.");
        }
      }
    }

    final uid = _uuid.v4();
    final newProfile = UserProfile(
      uid: uid,
      email: email.trim().toLowerCase(),
      displayName: name.trim(),
    );

    // Stocker dans la collection users avec le mot de passe pour la vérification future
    final dbData = newProfile.toJson();
    dbData['password'] = password; // uniquement pour la simulation locale !
    
    await _db.collection('users').doc(uid).set(dbData);
    
    _currentUser = newProfile;
    // Sauvegarder la session active
    await _db.collection('auth').doc('session').set(_currentUser!.toJson());
    
    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    await _db.collection('auth').doc('session').delete();
  }
}
