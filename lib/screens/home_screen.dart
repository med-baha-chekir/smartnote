// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:smartnote/screens/note_detail_screen.dart';
import 'package:smartnote/services/auth_service.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/widgets/note_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final NoteService _noteService = NoteService();
  QueryDocumentSnapshot? _lastDeletedNote;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes Notes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
        
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _noteService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Vous n'avez pas encore de notes.\nCliquez sur '+' pour commencer !",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }
          final notes = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 90.0), // Padding en bas
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final noteDocument = notes[index];
              final noteData = noteDocument.data() as Map<String, dynamic>;
              final noteId = noteDocument.id;
              final timestamp = noteData['createdAt'] as Timestamp?;
              String formattedDate = 'date inconnue';
              if (timestamp != null) {
                formattedDate = DateFormat.yMMMd('fr_FR').format(timestamp.toDate());
              }
              return Dismissible(
                key: Key(noteId),
                onDismissed: (direction) {
                  _lastDeletedNote = noteDocument;
                  _noteService.deleteNote(noteId);
                  ScaffoldMessenger.of(context).removeCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text("Note supprimée"),
                    action: SnackBarAction(
                      label: 'ANNULER',
                      onPressed: () {
                        if (_lastDeletedNote != null) {
                          final data = _lastDeletedNote!.data() as Map<String, dynamic>;
                          _noteService.addNote(data['title'] ?? '', data['content'] ?? '',
                              subject: data['subject'], createdAt: data['createdAt'], summary: data['summary']);
                        }
                      },
                    ),
                  ));
                },
                background: Container(
                    color: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    child: const Icon(Icons.delete_outline, color: Colors.white)),
                direction: DismissDirection.endToStart,
                child: NoteCard(
                  title: noteData['title'] ?? '',
                  previewContent: noteData['content'] ?? '',
                  date: formattedDate,
                  subject: noteData['subject'],
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: noteId))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}