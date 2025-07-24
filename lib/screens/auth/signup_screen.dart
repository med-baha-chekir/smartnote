// lib/screens/auth/signup_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/services/auth_service.dart';
import 'package:smartnote/utils/snackbar_helper.dart';
import 'package:smartnote/widgets/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // --- VERSION FINALE ET CORRIGÉE DE LA FONCTION _signUp ---
  void _signUp() async {
    // Si la fonction est déjà en cours d'exécution, on ne fait rien.
    if (_isLoading) return;
    // On ferme le clavier pour que l'utilisateur puisse voir les messages.
    FocusScope.of(context).unfocus();

    // Vérification initiale des mots de passe
    if (_passwordController.text != _confirmPasswordController.text) {
      SnackBarHelper.showError(context, "Les mots de passe ne correspondent pas.");
      return;
    }

    // On lance l'indicateur de chargement
    setState(() {
      _isLoading = true;
    });

    // On appelle le service et on attend le résultat (un message d'erreur ou null)
    final String? errorMessage = await _authService.signUpWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // Si le widget a été retiré de l'arbre pendant l'attente, on arrête.
    if (!mounted) return;

    // *** C'EST LA LOGIQUE CORRIGÉE ET INVERSÉE ***
    if (errorMessage == null) {
      // S'IL N'Y A PAS D'ERREUR (cas du succès) :
      // 1. L'AuthGate a déjà remplacé le fond par HomeScreen.
      // 2. On ferme cet écran (SignUpScreen) pour révéler HomeScreen.
      // PAS BESOIN d'arrêter le loader, car la page va disparaître.
      Navigator.of(context).pop();

    } else {
      // S'IL Y A UNE ERREUR :
      // 1. On arrête le chargement pour que le bouton redevienne cliquable.
      setState(() {
        _isLoading = false;
      });
      // 2. On affiche le message d'erreur et on reste sur la page.
      SnackBarHelper.showError(context, errorMessage);
    }
  }
  // --- FIN DE LA FONCTION CORRIGÉE ---

  @override
  Widget build(BuildContext context) {
    // Le reste de votre code build est parfait et n'a pas besoin de changer.
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text('Create Account', style: TextStyle(color: Colors.black)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text('Join SmartNote', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const Text('Start your learning journey today', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 40),

                CustomTextField(label: 'Full Name', hintText: 'Your full name', controller: _nameController, prefixIcon: Icons.person_outline),
                const SizedBox(height: 20),
                CustomTextField(label: 'Email', hintText: 'your.email@example.com', controller: _emailController, prefixIcon: Icons.email_outlined),
                const SizedBox(height: 20),
                CustomTextField(
                  label: 'Password',
                  hintText: '••••••••',
                  controller: _passwordController,
                  isPassword: !_isPasswordVisible,
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                ),
                const SizedBox(height: 20),
                CustomTextField(label: 'Confirm Password', hintText: '••••••••', controller: _confirmPasswordController, isPassword: true, prefixIcon: Icons.lock_outline),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text('Create Account'),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Log in'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}