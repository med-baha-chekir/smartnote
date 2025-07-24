// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Logger _logger = Logger();

  // --- Fonctions d'Authentification par Email/Mot de passe ---

  /// Tente d'inscrire un utilisateur.
  /// Renvoie `null` si l'inscription réussit.
  /// Renvoie un `String` contenant le message d'erreur si elle échoue.
  Future<String?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i('Inscription réussie pour: $email');
      return null; // Succès, pas de message d'erreur.

    } on FirebaseAuthException catch (e) {
      _logger.w('Erreur Firebase Auth (Inscription): ${e.code}');
      // On traduit les codes d'erreur de Firebase en messages clairs pour l'utilisateur.
      switch (e.code) {
        case 'weak-password':
          return 'Le mot de passe est trop faible.';
        case 'email-already-in-use':
          return 'Un compte existe déjà pour cette adresse e-mail.';
        case 'invalid-email':
          return 'L\'adresse e-mail n\'est pas valide.';
        default:
          return 'Une erreur d\'inscription est survenue.';
      }
    } catch (e) {
      _logger.e('Erreur inconnue (Inscription)', error: e);
      return 'Une erreur inconnue est survenue.';
    }
  }

  /// Tente de connecter un utilisateur.
  /// Renvoie `null` si la connexion réussit.
  /// Renvoie un `String` contenant le message d'erreur si elle échoue.
  Future<String?> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i('Connexion réussie pour: $email');
      return null; // Succès

    } on FirebaseAuthException catch (e) {
      _logger.w('Erreur Firebase Auth (Connexion): ${e.code}');
      // On utilise un seul message générique pour ne pas donner d'indices à des attaquants.
      return 'L\'adresse e-mail ou le mot de passe est incorrect.';
    } catch (e) {
      _logger.e('Erreur inconnue (Connexion)', error: e);
      return 'Une erreur inconnue est survenue.';
    }
  }

  // --- Fonction d'Authentification Sociale (Google) ---

  /// Tente de connecter un utilisateur avec Google.
  /// Renvoie `null` en cas de succès, un message d'erreur sinon.
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.i('Connexion Google annulée par l\'utilisateur.');
        return null; // Pas une erreur, juste une annulation.
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await _auth.signInWithCredential(credential);
      _logger.i('Connexion avec Google réussie pour: ${googleUser.email}');
      return null; // Succès

    } on FirebaseAuthException catch (e) {
        _logger.e('Erreur Firebase avec Google: ${e.code}');
        return 'Une erreur est survenue lors de la connexion avec Google.';
    }
     catch (e) {
      _logger.e('Erreur lors de la connexion avec Google', error: e);
      return 'Une erreur de connexion avec Google est survenue.';
    }
  }

  // --- Fonctions de Session ---

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    _logger.i('Utilisateur déconnecté');
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();
}