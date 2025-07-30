// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/firebase_options.dart';
import 'package:smartnote/services/auth_gate.dart'; // Le widget qui choisit quel écran afficher

// Définition de la couleur principale de votre application pour un accès facile
const Color primaryColor = Color(0xFFF97316); // Un orange vif, similaire au design

void main() async {
  // Assure que tous les bindings Flutter sont initialisés
  // avant d'exécuter du code asynchrone (comme Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Firebase avec les options de configuration spécifiques à la plateforme
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Lance l'application Flutter
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Le titre de votre application (utilisé par le système d'exploitation)
      title: 'SmartNote',

      // Retire la petite bannière "Debug" en haut à droite
      debugShowCheckedModeBanner: false,

      // --- Définition du Thème Global de l'Application ---
      theme: ThemeData(
        // Indique l'utilisation de Material 3, le dernier système de design de Google
        useMaterial3: true,
        
        // Couleur principale utilisée dans toute l'application
        primaryColor: primaryColor,
        
        // Couleur de fond par défaut pour la plupart des écrans
        scaffoldBackgroundColor: Colors.grey.shade50, // Un gris très clair, presque blanc

        // Thème pour la barre du haut (AppBar)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent, // Fond transparent pour se fondre avec le scaffold
          elevation: 0, // Aucune ombre
          iconTheme: IconThemeData(color: Colors.black), // Icônes noires (ex: flèche de retour)
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Thème pour les boutons principaux (ElevatedButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor, // Fond orange
            foregroundColor: Colors.white, // Texte blanc
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Thème pour les liens textes (TextButton)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: primaryColor, // Texte orange
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Le ColorScheme définit une palette de couleurs cohérente.
        // fromSeed génère des variations (claires, foncées) à partir de votre couleur principale.
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      ),
      // --- Fin du Thème ---

      // Le widget de démarrage de l'application.
      // On utilise un "AuthGate" pour vérifier si l'utilisateur est déjà connecté.
      // S'il est connecté, on montre HomeScreen. Sinon, on montre LoginScreen.
      home: const AuthGate(),
    );
  }
}