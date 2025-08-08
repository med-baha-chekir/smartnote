// lib/screens/subject_detail_screen.dart

import 'package:async/async.dart'; // <-- N'oubliez pas cet import !
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartnote/screens/note_detail_screen.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/widgets/note_card.dart';
import 'package:collection/collection.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subject;
  const SubjectDetailScreen({super.key, required this.subject});

  // --- NOUVELLE FONCTION HELPER POUR DÉTERMINER LA COULEUR ---
  Color _getStatusColor(QueryDocumentSnapshot note, List<QueryDocumentSnapshot> quizResults) {
    // On cherche le résultat de quiz pour CETTE note spécifique
    final resultDoc = quizResults.firstWhereOrNull(
      (result) => (result.data() as Map<String, dynamic>)['noteId'] == note.id,
     );

    // Si aucun quiz n'a été fait pour cette note, pas de couleur
    if (resultDoc == null) {
      return Colors.transparent;
    }

    final resultData = resultDoc.data() as Map<String, dynamic>;
    final score = resultData['score'] as int? ?? 0;
    final totalQuestions = resultData['totalQuestions'] as int? ?? 1; // On met 1 pour éviter la division par zéro

    // On calcule le pourcentage
    final double percentage = score / totalQuestions;

    // On retourne la couleur en fonction du score
    if (percentage == 1.0) {
      return Colors.green; // 100% -> Vert
    } else if (percentage >= 0.6) { // 60% et plus (ex: 3/5)
      return Colors.orange; // -> Orange
    } else {
      return Colors.red; // Moins de 60% -> Rouge
    }
  }
  // --- FIN DE LA FONCTION HELPER ---

  @override
  Widget build(BuildContext context) {
    final NoteService noteService = NoteService();

    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: StreamBuilder<List<QuerySnapshot>>(
        // On combine le flux des notes de cette matière ET de tous les résultats de quiz
        stream: StreamZip([
          noteService.getNotesStreamBySubject(subject),
          noteService.getQuizResultsStream(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data![0].docs.isEmpty) {
            return const Center(child: Text('Aucune note pour cette matière.'));
          }

          final notes = snapshot.data![0].docs;
          final quizResults = snapshot.data![1].docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final noteDoc = notes[index];
              final noteData = noteDoc.data() as Map<String, dynamic>;
              final noteId = noteDoc.id;
              
              final timestamp = noteData['createdAt'] as Timestamp?;
              String formattedDate = 'date inconnue';
              if (timestamp != null) {
                formattedDate = DateFormat.yMMMd('fr_FR').format(timestamp.toDate());
              }

              // On détermine la couleur du statut pour cette note
              final statusColor = _getStatusColor(noteDoc, quizResults);

              return Stack(
                // On utilise clipBehavior.none pour que le cercle puisse "déborder" de la carte
                clipBehavior: Clip.none, 
                children: [
                  // Enfant 1 : La carte de note (prend toute la place)
                  Padding(
                    // On ajoute un petit padding à droite pour laisser de la place au cercle
                    padding: const EdgeInsets.only(right: 8.0),
                    child: NoteCard(
                      title: noteData['title'] ?? '',
                      previewContent: noteData['content'] ?? '',
                      date: formattedDate,
                      subject: noteData['subject'],
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: noteId))),
                    ),
                  ),

                  // Enfant 2 : Le cercle de statut, positionné par-dessus
                  // On l'affiche seulement si une couleur de statut existe
                  if (statusColor != Colors.transparent)
                    Positioned(
                      top: -5,  // Distance depuis le haut de la carte
                      right: 0, // Collé sur le bord droit
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                          // On peut ajouter une petite bordure blanche pour le faire ressortir
                          border: Border.all(color: Colors.white, width: 2), 
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}