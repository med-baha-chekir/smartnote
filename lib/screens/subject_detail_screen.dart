// lib/screens/subject_detail_screen.dart

import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartnote/screens/note_detail_screen.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/widgets/note_card.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subject;
  const SubjectDetailScreen({super.key, required this.subject});

  // --- NOUVELLE FONCTION POUR CALCULER LE NOMBRE D'ÉTOILES ---
  int _calculateStarRating(QueryDocumentSnapshot note, List<QueryDocumentSnapshot> quizResults) {
    final resultDoc = quizResults.firstWhereOrNull(
      (result) => (result.data() as Map<String, dynamic>)['noteId'] == note.id,
    );

    if (resultDoc == null) return 0; // 0 étoile si aucun quiz n'a été fait

    final resultData = resultDoc.data() as Map<String, dynamic>;
    final score = resultData['score'] as int? ?? 0;
    final totalQuestions = resultData['totalQuestions'] as int? ?? 1;
    final double percentage = totalQuestions > 0 ? score / totalQuestions : 0.0;

    // Convertit le pourcentage en une note sur 5
    if (percentage >= 0.95) return 5;
    if (percentage >= 0.8) return 4;
    if (percentage >= 0.6) return 3;
    if (percentage >= 0.4) return 2;
    if (percentage >= 0.2) return 1;
    return 0;
  }

  // --- NOUVEAU WIDGET DE CONSTRUCTION POUR AFFICHER LES ÉTOILES ---
 

  @override
  Widget build(BuildContext context) {
    final NoteService noteService = NoteService();

    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: StreamBuilder<List<QuerySnapshot>>(
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

              // On calcule la note en étoiles pour cette note
              final int starRating = _calculateStarRating(noteDoc, quizResults);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- LA RANGÉE D'ÉTOILES ---
                  // On ne l'affiche que s'il y a un quiz de fait
                  

                  // --- LA CARTE DE NOTE ---
                  NoteCard(
                    title: noteData['title'] ?? '',
                    previewContent: noteData['content'] ?? '',
                    date: formattedDate,
                    subject: noteData['subject'],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: noteId))),
                    rating: starRating,
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