// lib/screens/auth/signup_screen.dart

import 'package:flutter/material.dart';
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
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () { /* TODO: Recréer la logique d'inscription ici */ },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Account', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account?"),
                    TextButton(
                      onPressed: () {
                        // Ici, on veut bien revenir à la page de connexion, donc on
                        // retire la page actuelle de la pile de navigation.
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