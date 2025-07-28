// lib/widgets/note_card.dart

import 'package:flutter/material.dart';

class NoteCard extends StatelessWidget {
  final String title;
  final String previewContent;
  final String date;
  final String? subject; // Le sujet est optionnel
  final VoidCallback onTap;

  const NoteCard({
    super.key,
    required this.title,
    required this.previewContent,
    required this.date,
    this.subject,
    required this.onTap,
  });

  // --- MAP DE COULEURS POUR LES SUJETS ---
  // Vous pouvez personnaliser cette liste à volonté.
  static final Map<String, Color> _subjectColors = {
    'Histoire': Colors.blue.shade300,
    'Biologie': Colors.green.shade300,
    'Mathématiques': Colors.purple.shade300,
    'Physique': Colors.orange.shade300,
    'Chimie': Colors.red.shade300,
    'Général': const Color.fromARGB(255, 148, 147, 147), // Une couleur par défaut
  };
  // --- FIN DE LA MAP ---

  // Fonction pour obtenir la bonne couleur en fonction du sujet.
  Color _getSubjectColor() {
    // Si le sujet existe dans notre map, on utilise sa couleur.
    // Sinon, on prend la couleur 'Général'.
    return _subjectColors[subject] ?? _subjectColors['Général']!;
  }

  @override
  Widget build(BuildContext context) {
    // On récupère la couleur une seule fois pour la réutiliser.
    final Color subjectColor = _getSubjectColor();

    return Card(
      elevation: 1.0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color.fromARGB(255, 255, 255, 255),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          // On ajoute un Container pour pouvoir dessiner la bordure.
          decoration: BoxDecoration(
            border: Border(
              // *** AMÉLIORATION 1 : Bordure latérale colorée ***
              left: BorderSide(color: subjectColor, width: 6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16), // Padding ajusté pour la bordure
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title.isEmpty ? 'Note sans titre' : title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10), // Espace
                    if (subject != null && subject!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          // *** AMÉLIORATION 2 : Fond du tag coloré ***
                          color: subjectColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          subject!,
                          style: TextStyle(
                            // *** AMÉLIORATION 3 : Texte du tag coloré ***
                            color: subjectColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  previewContent.isEmpty ? 'Aucun contenu' : previewContent,
                  style: const TextStyle(color: Colors.grey),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  'Modifié $date',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}