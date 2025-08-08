// lib/services/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/screens/auth/login_screen.dart';
import 'package:smartnote/screens/home_screen.dart';
import 'package:smartnote/screens/main_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // On écoute en temps réel les changements d'état de l'authentification
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Cas 1: On attend encore une réponse de Firebase
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Cas 2: On a reçu une réponse ET l'utilisateur est bien connecté (non null)
        if (snapshot.hasData) {
          return const MainScreen(); // Alors on affiche l'écran d'accueil
        }

        // Cas 3: On a reçu une réponse mais l'utilisateur est null (déconnecté)
        return const LoginScreen(); // Alors on affiche l'écran de connexion
      },
    );
  }
}