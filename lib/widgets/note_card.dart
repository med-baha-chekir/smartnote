// lib/widgets/note_card.dart

import 'package:flutter/material.dart';
import 'package:smartnote/utils/app_colors.dart';

class NoteCard extends StatelessWidget {
  final String title;
  final String previewContent;
  final String date;
  final String? subject;
  final VoidCallback onTap;
  
  // --- DÉBUT DE L'AJOUT ---
  final int? rating; // Nouveau paramètre optionnel pour la note
  // --- FIN DE L'AJOUT ---

  const NoteCard({
    super.key,
    required this.title,
    required this.previewContent,
    required this.date,
    this.subject,
    required this.onTap,
    this.rating, // <-- On l'ajoute au constructeur
  });

  // --- DÉBUT DE L'AJOUT ---
  /// Construit la rangée de 5 étoiles en fonction de la note.
  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: Colors.amber.shade600,
          size: 18,
        );
      }),
    );
  }
  // --- FIN DE L'AJOUT ---

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = AppColors.getColorForSubject(subject);

    return Card(
      elevation: 4.0,
      shadowColor: Colors.black.withOpacity(0.08), // J'ai adouci l'ombre pour un meilleur look
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
                        color: subjectColor,
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
              
              // --- DÉBUT DE LA MODIFICATION ---
              // On remplace le simple Text par une Row pour aligner la date et les étoiles.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Modifié $date',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  
                  // On affiche les étoiles seulement si un 'rating' est fourni.
                  if (rating != null)
                    _buildStarRating(rating!),
                ],
              ),
              // --- FIN DE LA MODIFICATION ---
            ],
          ),
        ),
      ),
    );
  }
}