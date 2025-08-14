// lib/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  static final List<String> availableSubjects = [
    'Général',
    'Histoire',
    'Biologie',
    'Mathématiques',
    'Physique',
    // Ajoutez d'autres matières ici
  ];
  
  static final Map<String, Color> subjectColors = {
    'Histoire': const Color(0xFFFDE68A),
    'Biologie': const Color(0xFFA7F3D0),
    'Mathématiques': const Color(0xFFC4B5FD),
    'Physique': const Color(0xFFFBCFE8),
    'Général': Colors.grey.shade200,
    // Ajoutez d'autres matières ici
  };

  static Color getColorForSubject(String? subject) {
    return subjectColors[subject] ?? subjectColors['Général']!;
  }
}