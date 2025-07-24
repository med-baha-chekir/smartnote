// lib/utils/snackbar_helper.dart

import 'package:flutter/material.dart';

class SnackBarHelper {
  // Affiche une SnackBar standard
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // Affiche une SnackBar d'erreur avec une couleur rouge
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }
}