// lib/screens/subject_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartnote/screens/note_detail_screen.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/widgets/note_card.dart';

class SubjectDetailScreen extends StatelessWidget {
  final String subject;
  const SubjectDetailScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final NoteService noteService = NoteService();

    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: StreamBuilder<QuerySnapshot>(
        stream: noteService.getNotesStreamBySubject(subject),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune note pour cette matière.'));
          }

          final notes = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final noteData = notes[index].data() as Map<String, dynamic>;
              final noteId = notes[index].id;
              final timestamp = noteData['createdAt'] as Timestamp?;
              String formattedDate = 'date inconnue';
              if (timestamp != null) {
                formattedDate = DateFormat.yMMMd('fr_FR').format(timestamp.toDate());
              }

              // On réutilise notre magnifique NoteCard !
              return NoteCard(
                title: noteData['title'] ?? '',
                previewContent: noteData['content'] ?? '',
                date: formattedDate,
                subject: noteData['subject'],
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: noteId))),
              );
            },
          );
        },
      ),
    );
  }
}