import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart' as fb_store;
import 'package:firedart/firedart.dart' as fd;
import '../models/user_profile.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  bool get isDesktopNative => !kIsWeb && (Platform.isLinux || Platform.isWindows);

  fb_auth.FirebaseAuth get _auth => fb_auth.FirebaseAuth.instance;
  fb_store.FirebaseFirestore get _firestore => fb_store.FirebaseFirestore.instance;

  @override
  Future<void> init() async {
    // Aucune initialisation requise
  }

  @override
  Future<UserProfile?> getCurrentUser() async {
    if (isDesktopNative) {
      if (fd.FirebaseAuth.instance.isSignedIn) {
        final uid = fd.FirebaseAuth.instance.userId;
        try {
          final doc = await fd.Firestore.instance.collection('users').document(uid).get();
          if (doc.map.isNotEmpty) {
            return UserProfile.fromJson(doc.map);
          }
        } catch (_) {}

        // Créer ou récupérer les infos de base
        try {
          final user = await fd.FirebaseAuth.instance.getUser();
          final isDefaultAdmin = user.email?.toLowerCase() == 'admin@admin.com';
          final profile = UserProfile(
            uid: uid,
            email: user.email ?? '',
            displayName: (isDefaultAdmin ? 'Administrateur' : 'Utilisateur'),
            isAdmin: isDefaultAdmin,
          );
          await updateUser(profile);
          return profile;
        } catch (_) {}
      }
      return null;
    } else {
      final fbUser = _auth.currentUser;
      if (fbUser == null) return null;

      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson(doc.data()!);
      }

      final isDefaultAdmin = fbUser.email?.toLowerCase() == 'admin@admin.com';
      final profile = UserProfile(
        uid: fbUser.uid,
        email: fbUser.email ?? '',
        displayName: fbUser.displayName ?? (isDefaultAdmin ? 'Administrateur' : 'Utilisateur'),
        isAdmin: isDefaultAdmin,
      );
      await updateUser(profile);
      return profile;
    }
  }

  @override
  Future<UserProfile> signIn(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      throw Exception("L'email et le mot de passe ne peuvent pas être vides.");
    }

    if (isDesktopNative) {
      try {
        await fd.FirebaseAuth.instance.signIn(email.trim(), password);
        final uid = fd.FirebaseAuth.instance.userId;
        try {
          final doc = await fd.Firestore.instance.collection('users').document(uid).get();
          if (doc.map.isNotEmpty) {
            return UserProfile.fromJson(doc.map);
          }
        } catch (_) {}

        final isDefaultAdmin = email.trim().toLowerCase() == 'admin@admin.com';
        final profile = UserProfile(
          uid: uid,
          email: email.trim().toLowerCase(),
          displayName: isDefaultAdmin ? 'Administrateur' : 'Utilisateur',
          isAdmin: isDefaultAdmin,
        );
        await updateUser(profile);
        return profile;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('invalid_email') || msg.contains('invalid-email')) {
          throw Exception("Format d'adresse email invalide.");
        } else if (msg.contains('invalid_password') || msg.contains('wrong-password') || msg.contains('wrong password') || msg.contains('invalid credential')) {
          throw Exception("Mot de passe incorrect.");
        } else if (msg.contains('user_not_found') || msg.contains('user-not-found')) {
          throw Exception("Aucun utilisateur trouvé avec cet email. Veuillez créer un compte.");
        } else {
          throw Exception(e.toString().replaceAll("Exception: ", ""));
        }
      }
    } else {
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

        final isDefaultAdmin = email.trim().toLowerCase() == 'admin@admin.com';
        final profile = UserProfile(
          uid: fbUser.uid,
          email: fbUser.email ?? email,
          displayName: fbUser.displayName ?? (isDefaultAdmin ? 'Administrateur' : 'Utilisateur'),
          isAdmin: isDefaultAdmin,
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
  }

  @override
  Future<UserProfile> signUp(String email, String password, String name) async {
    if (email.trim().isEmpty || password.trim().isEmpty || name.trim().isEmpty) {
      throw Exception("Tous les champs sont obligatoires.");
    }

    if (isDesktopNative) {
      try {
        await fd.FirebaseAuth.instance.signUp(email.trim().toLowerCase(), password);
        final uid = fd.FirebaseAuth.instance.userId;
        final profile = UserProfile(
          uid: uid,
          email: email.trim().toLowerCase(),
          displayName: name.trim(),
          isAdmin: false,
        );
        await updateUser(profile);
        return profile;
      } catch (e) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('email_exists') || msg.contains('email-already-in-use')) {
          throw Exception("Cet email est déjà utilisé par un autre compte.");
        } else if (msg.contains('weak_password') || msg.contains('weak-password')) {
          throw Exception("Le mot de passe est trop faible. Il doit contenir au moins 6 caractères.");
        } else if (msg.contains('invalid_email') || msg.contains('invalid-email')) {
          throw Exception("Format d'adresse email invalide.");
        } else {
          throw Exception(e.toString().replaceAll("Exception: ", ""));
        }
      }
    } else {
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
  }

  @override
  Future<void> signOut() async {
    if (isDesktopNative) {
      fd.FirebaseAuth.instance.signOut();
    } else {
      await _auth.signOut();
    }
  }

  @override
  Future<List<UserProfile>> getAllUsers() async {
    try {
      if (isDesktopNative) {
        final querySnapshot = await fd.Firestore.instance.collection('users').get();
        return querySnapshot
            .map((doc) => UserProfile.fromJson(doc.map))
            .toList();
      } else {
        final querySnapshot = await _firestore.collection('users').get();
        return querySnapshot.docs
            .map((doc) => UserProfile.fromJson(doc.data()))
            .toList();
      }
    } catch (e) {
      throw Exception("Erreur lors de la récupération des utilisateurs : $e");
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      if (isDesktopNative) {
        await fd.Firestore.instance.collection('users').document(uid).delete();
      } else {
        await _firestore.collection('users').doc(uid).delete();
      }
    } catch (e) {
      throw Exception("Erreur lors de la suppression de l'utilisateur : $e");
    }
  }

  @override
  Future<void> updateUser(UserProfile user) async {
    try {
      if (isDesktopNative) {
        await fd.Firestore.instance.collection('users').document(user.uid).set(user.toJson());
      } else {
        await _firestore.collection('users').doc(user.uid).set(user.toJson(), fb_store.SetOptions(merge: true));
      }
    } catch (e) {
      throw Exception("Erreur lors de la mise à jour de l'utilisateur : $e");
    }
  }
}
