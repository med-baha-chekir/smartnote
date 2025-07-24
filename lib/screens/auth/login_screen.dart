// lib/screens/auth/login_screen.dart

import 'package:flutter/material.dart';
import 'package:smartnote/screens/auth/signup_screen.dart';
import 'package:smartnote/services/auth_service.dart';
import 'package:smartnote/utils/snackbar_helper.dart'; // N'oubliez pas cet import !
import 'package:smartnote/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// Dans lib/screens/auth/login_screen.dart

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // --- FONCTION POUR LA CONNEXION EMAIL ---
  void _signIn() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final String? errorMessage = await _authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    if (errorMessage != null) {
      setState(() => _isLoading = false);
      SnackBarHelper.showError(context, errorMessage);
    }
    // Si succès, AuthGate gère la redirection, donc on ne fait rien ici
  }

  // --- NOUVELLE FONCTION (PROPRE) POUR LA CONNEXION GOOGLE ---
  void _signInWithGoogle() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final String? errorMessage = await _authService.signInWithGoogle();

    if (!mounted) return;

    // On arrête le chargement uniquement si la connexion a échoué.
    // En cas de succès, AuthGate s'occupe de tout.
    if (errorMessage != null) {
      setState(() => _isLoading = false);
      SnackBarHelper.showError(context, errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: AbsorbPointer( // <-- Enveloppe tout pour désactiver les clics pendant le chargement
              absorbing: _isLoading,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ... (Le reste de votre UI : Logo, Titre, Champs de texte, etc. reste pareil)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.book_outlined, size: 40, color: Theme.of(context).primaryColor),const SizedBox(width: 10),const Text('SmartNote', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),],),
                  const SizedBox(height: 16),
                  const Text('Welcome back!', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const Text('Sign in to continue your learning journey', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),
                  CustomTextField(label: 'Email', hintText: 'your.email@example.com', prefixIcon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress,),
                  const SizedBox(height: 20),
                  CustomTextField(label: 'Password', hintText: '••••••••', prefixIcon: Icons.lock_outline, controller: _passwordController, isPassword: !_isPasswordVisible, suffixIcon: IconButton(icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),),),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('Forgot password?')),),
                  const SizedBox(height: 20),


                  // Bouton Log In
                  ElevatedButton(
                    onPressed: _signIn,
                    child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Log In'),
                  ),
                  const SizedBox(height: 24),
                  
                  // Séparateur
                  const Row(children: [ Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Or continue with', style: TextStyle(color: Colors.grey))), Expanded(child: Divider()), ]),
                  const SizedBox(height: 24),

                  // --- SECTION IMPORTANTE : BOUTONS SOCIAUX ---
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          // On appelle notre nouvelle fonction dédiée
                          onPressed: _signInWithGoogle,
                          icon: Image.asset('assets/google-logo.png', height: 20),
                          label: const Text('Google', style: TextStyle(color: Colors.black)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implémenter la connexion Apple
                            SnackBarHelper.show(context, "La connexion avec Apple n'est pas encore disponible.");
                          },
                          icon: const Icon(Icons.apple, color: Colors.black),
                          label: const Text('Apple', style: TextStyle(color: Colors.black)),
                           style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // ... (Lien vers l'inscription)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [ const Text("Don't have an account yet?"), TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen())), child: const Text('Sign up'),),])
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}