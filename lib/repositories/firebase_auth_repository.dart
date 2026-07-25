import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import '../models/user_profile.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  fb_auth.FirebaseAuth get _auth => fb_auth.FirebaseAuth.instance;
  fb_store.FirebaseFirestore get _firestore => fb_store.FirebaseFirestore.instance;

  @override
  Future<void> init() async {
    // Aucune initialisation requise
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;

    final doc = await _firestore.collection('users').doc(fbUser.uid).get();
    if (doc.exists && doc.data() != null) {
      return UserProfile.fromJson(doc.data()!);
    }

    final profile = UserProfile(
      uid: fbUser.uid,
      email: fbUser.email ?? '',
      displayName: fbUser.displayName ?? 'Utilisateur',
      isAdmin: false,
    );
    await updateUser(profile);
    return profile;
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception("L'email et le mot de passe ne peuvent pas être vides.");
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) throw Exception("Erreur lors de la connexion.");

      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }

      final profile = UserProfile(
        uid: fbUser.uid,
        email: fbUser.email ?? email,
        displayName: fbUser.displayName ?? 'Utilisateur',
        isAdmin: false,
      );
      await updateUser(profile);
      return profile;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception("Aucun utilisateur trouvé avec cet email. Veuillez créer un compte.");
      } else if (e.code == 'wrong-password') {
        throw Exception("Mot de passe incorrect.");
      } else if (e.code == 'invalid-email') {
        throw Exception("Format d'adresse email invalide.");
      } else {
        throw Exception(e.message ?? "Erreur lors de la connexion.");
      }
    }
  }

  @override
  Future<UserProfile> signUp(String email, String password, String name, {DateTime? birthDate}) async {
    if (email.trim().isEmpty || password.trim().isEmpty || name.trim().isEmpty) {
      throw Exception("Tous les champs sont obligatoires.");
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) throw Exception("Erreur lors de la création du compte.");

      await fbUser.updateDisplayName(name.trim());

      final profile = UserProfile(
        uid: fbUser.uid,
        email: email.trim().toLowerCase(),
        displayName: name.trim(),
        birthDate: birthDate,
        isAdmin: false,
      );

      await _firestore.collection('users').doc(profile.uid).set(profile.toJson());
      return profile;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception("Cet email est déjà utilisé par un autre compte.");
      } else if (e.code == 'weak-password') {
        throw Exception("Le mot de passe est trop faible. Il doit contenir au moins 6 caractères.");
      } else if (e.code == 'invalid-email') {
        throw Exception("Format d'adresse email invalide.");
      } else {
        throw Exception(e.message ?? "Erreur lors de la création du compte.");
      }
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<List<UserProfile>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      return querySnapshot.docs
          .map((doc) => UserProfile.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception("Erreur lors de la récupération des utilisateurs : $e");
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception("Erreur lors de la suppression de l'utilisateur : $e");
    }
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set(user.toJson(), fb_store.SetOptions(merge: true));
    } catch (e) {
      throw Exception("Erreur lors de la mise à jour de l'utilisateur : $e");
    }
  }
}
