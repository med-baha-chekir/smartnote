// lib/services/auth_gate.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/screens/auth/login_screen.dart';
import 'package:smartnote/screens/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // On écoute le stream de Firebase Auth
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Si on attend encore les données, on affiche un indicateur de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si on a des données et que l'utilisateur n'est pas null, il est connecté
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeScreen(); // -> Diriger vers l'écran d'accueil
        }
        
        // Sinon, l'utilisateur n'est pas connecté
        return const LoginScreen(); // -> Diriger vers l'écran de connexion
      },
    );
  }
}