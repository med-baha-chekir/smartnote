// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:smartnote/services/auth_service.dart'; // On importe le service pour la déconnexion

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // On crée une instance de notre service
    final AuthService authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        // Le titre de la page d'accueil
        title: const Text('Mes Notes'),
        // La section des actions à droite de la barre
        actions: [
          // Bouton d'icône pour la déconnexion
          IconButton(
            tooltip: 'Se déconnecter', // Texte qui s'affiche au survol
            icon: const Icon(Icons.logout),
            onPressed: () {
              // On appelle la fonction de déconnexion de notre service
              authService.signOut();
            },
          ),
        ],
      ),
      body: const Center(
        // Un message de bienvenue temporaire
        child: Text('Bienvenue sur SmartNote !'),
      ),
    );
  }
}