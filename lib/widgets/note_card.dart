// lib/widgets/note_card.dart

import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final String title;
  final String previewContent;
  final String date;
  final String? subject;
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.title,
    required this.previewContent,
    required this.date,
    this.subject,
    required this.onTap,
  });

  // --- NOUVELLE PALETTE DE COULEURS PLUS DOUCES ---
  static final Map<String, Color> _subjectColors = {
    'Histoire': const Color(0xFFFDE68A), // Jaune doux
    'Biologie': const Color(0xFFA7F3D0), // Vert doux
    'Mathématiques': const Color(0xFFC4B5FD), // Violet doux
    'Physique': const Color(0xFFFBCFE8), // Rose doux
    'Général': Colors.grey.shade200,
  };
  
  Color _getSubjectBackgroundColor() {
    return _subjectColors[subject] ?? _subjectColors['Général']!;
  }

  Color _getSubjectTextColor() {
    // On peut rendre ça plus intelligent plus tard, mais pour l'instant on utilise du noir
    return Colors.black87;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4.0, // Un peu plus d'ombre pour un effet "flottant"
      shadowColor: Colors.black.withOpacity(0.8),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color.fromARGB(255, 255, 255, 255),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title.isEmpty ? 'Nouvelle Note' : title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (subject != null && subject!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getSubjectBackgroundColor(),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subject!,
                        style: TextStyle(
                          color: _getSubjectTextColor(),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                previewContent.isEmpty ? 'Aucun contenu' : previewContent,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Text(
                'Modifié $date',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}