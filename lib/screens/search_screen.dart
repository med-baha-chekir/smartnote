// lib/screens/search_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/widgets/note_card.dart'; // On réutilise notre belle NoteCard
import 'package:smartnote/screens/note_detail_screen.dart';
import 'package:intl/intl.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final NoteService _noteService = NoteService();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Rechercher par titre...',
            border: InputBorder.none,
            // On ajoute une icône pour effacer la recherche
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                      });
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 18),
          onChanged: (value) {
            // On met à jour l'état à chaque fois que l'utilisateur tape
            setState(() {
              _query = value;
            });
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Le flux est maintenant dynamique et dépend de la recherche
        stream: _noteService.searchNotes(_query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                _query.isEmpty
                    ? 'Commencez à taper pour rechercher.'
                    : 'Aucun résultat pour "$_query"',
              ),
            );
          }

          final notes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final noteData = notes[index].data() as Map<String, dynamic>;
              final noteId = notes[index].id;
              
              // On réutilise notre code de formatage de date
              final timestamp = noteData['createdAt'] as Timestamp?;
              String formattedDate = 'date inconnue';
              if (timestamp != null) {
                formattedDate = DateFormat.yMMMd('fr_FR').format(timestamp.toDate());
              }

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