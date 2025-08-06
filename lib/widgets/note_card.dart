// lib/widgets/note_card.dart

import 'package:flutter/material.dart';
import 'package:smartnote/utils/app_colors.dart'; // <-- On importe notre fichier de couleurs

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

  @override
  Widget build(BuildContext context) {
    // On récupère la couleur depuis notre classe centralisée
    final Color subjectColor = AppColors.getColorForSubject(subject);

    return Card(
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.4),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
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
                        color: subjectColor, // On utilise la couleur ici
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        subject!,
                        style: TextStyle(
                          color: Colors.black87,
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