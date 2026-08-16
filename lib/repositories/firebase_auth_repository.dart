import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import '../models/user_profile.dart';
import '../utils/security_utils.dart';
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
    final sanitizedEmail = email.trim();
    if (sanitizedEmail.isEmpty || password.isEmpty) {
      throw Exception("L'adresse email et le mot de passe ne peuvent pas être vides.");
    }

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: sanitizedEmail,
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
        email: fbUser.email ?? sanitizedEmail,
        displayName: fbUser.displayName ?? 'Utilisateur',
        isAdmin: false,
      );
      await updateUser(profile);
      return profile;
    } on fb_auth.FirebaseAuthException catch (e) {
      // Protection anti-énumération de comptes
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Identifiants invalides : adresse email ou mot de passe incorrect.");
      } else if (e.code == 'invalid-email') {
        throw Exception("Format d'adresse email invalide.");
      } else if (e.code == 'user-disabled') {
        throw Exception("Ce compte utilisateur a été désactivé.");
      } else if (e.code == 'too-many-requests') {
        throw Exception("Trop de tentatives infructueuses. Veuillez patienter avant de réessayer.");
      } else {
        throw Exception(e.message ?? "Erreur lors de la connexion.");
      }
    }
  }

  @override
  Future<UserProfile> signUp(String email, String password, String name, {DateTime? birthDate}) async {
    final sanitizedEmail = email.trim().toLowerCase();
    final sanitizedName = name.trim();

    if (sanitizedEmail.isEmpty || password.isEmpty || sanitizedName.isEmpty) {
      throw Exception("Tous les champs obligatoires doivent être renseignés.");
    }

    final passwordError = SecurityUtils.validatePassword(password);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: sanitizedEmail,
        password: password,
      );

      final fbUser = userCredential.user;
      if (fbUser == null) throw Exception("Erreur lors de la création du compte.");

      await fbUser.updateDisplayName(sanitizedName);

      // Envoi de l'e-mail de vérification
      try {
        await fbUser.sendEmailVerification();
      } catch (_) {
        // Envoi silencieux si échec réseau immédiat
      }

      final profile = UserProfile(
        uid: fbUser.uid,
        email: sanitizedEmail,
        displayName: sanitizedName,
        birthDate: birthDate,
        isAdmin: false,
      );

      await _firestore.collection('users').doc(profile.uid).set(profile.toJson());
      return profile;
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception("Cette adresse email est déjà associée à un compte.");
      } else if (e.code == 'weak-password') {
        throw Exception("Le mot de passe est trop faible.");
      } else if (e.code == 'invalid-email') {
        throw Exception("Format d'adresse email invalide.");
      } else if (e.code == 'too-many-requests') {
        throw Exception("Trop de requêtes. Veuillez patienter un instant.");
      } else {
        throw Exception(e.message ?? "Erreur lors de la création du compte.");
      }
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final sanitizedEmail = email.trim();
    if (sanitizedEmail.isEmpty) {
      throw Exception("Veuillez saisir votre adresse email.");
    }
    if (!SecurityUtils.isValidEmail(sanitizedEmail)) {
      throw Exception("Veuillez saisir une adresse email valide.");
    }

    try {
      await _auth.sendPasswordResetEmail(email: sanitizedEmail);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        throw Exception("Format d'adresse email invalide.");
      } else if (e.code == 'too-many-requests') {
        throw Exception("Trop de demandes. Veuillez patienter avant de réessayer.");
      } else {
        // Par sécurité anti-énumération, ne pas exposer si l'email existe ou non en cas de succès apparent
      }
    } catch (e) {
      throw Exception("Erreur lors de l'envoi de l'email de réinitialisation : $e");
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Aucun utilisateur connecté.");
    if (user.emailVerified) return;

    try {
      await user.sendEmailVerification();
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'too-many-requests') {
        throw Exception("Trop de demandes d'envoi. Veuillez patienter.");
      } else {
        throw Exception(e.message ?? "Erreur lors de l'envoi du mail de vérification.");
      }
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception("Aucun utilisateur connecté.");
    }

    final passwordError = SecurityUtils.validatePassword(newPassword);
    if (passwordError != null) {
      throw Exception(passwordError);
    }

    try {
      // Re-authentification obligatoire pour opération sensible
      final credential = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Le mot de passe actuel est incorrect.");
      } else if (e.code == 'weak-password') {
        throw Exception("Le nouveau mot de passe est trop faible.");
      } else if (e.code == 'requires-recent-login') {
        throw Exception("Cette opération nécessite une reconnexion récente.");
      } else {
        throw Exception(e.message ?? "Erreur lors du changement de mot de passe.");
      }
    }
  }

  @override
  Future<void> updateEmail({required String currentPassword, required String newEmail}) async {
    final user = _auth.currentUser;
    final sanitizedEmail = newEmail.trim().toLowerCase();

    if (user == null || user.email == null) {
      throw Exception("Aucun utilisateur connecté.");
    }
    if (!SecurityUtils.isValidEmail(sanitizedEmail)) {
      throw Exception("Format d'adresse email invalide.");
    }

    try {
      final credential = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      // Envoie un email de vérification à la nouvelle adresse avant de modifier
      await user.verifyBeforeUpdateEmail(sanitizedEmail);

      // Met également à jour le document Firestore
      await _firestore.collection('users').doc(user.uid).set(
        {'email': sanitizedEmail},
        fb_store.SetOptions(merge: true),
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Le mot de passe actuel est incorrect.");
      } else if (e.code == 'email-already-in-use') {
        throw Exception("Cette adresse email est déjà utilisée.");
      } else if (e.code == 'requires-recent-login') {
        throw Exception("Cette opération nécessite une reconnexion récente.");
      } else {
        throw Exception(e.message ?? "Erreur lors du changement d'adresse email.");
      }
    }
  }

  @override
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
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

