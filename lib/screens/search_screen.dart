// lib/screens/search_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartnote/screens/note_detail_screen.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/widgets/note_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final NoteService _noteService = NoteService();
  final _searchController = TextEditingController();

  List<QueryDocumentSnapshot> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  List<QueryDocumentSnapshot> _filterNotes(List<QueryDocumentSnapshot> allNotes) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) {
      return allNotes;
    }
    return allNotes.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toLowerCase();
      final content = (data['content'] ?? '').toLowerCase();
      final summary = (data['summary'] ?? '').toLowerCase();
      return title.contains(query) || content.contains(query) || summary.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Recherche',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Rechercher titre, contenu, résumé...',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                filled: true,
                fillColor: Color(0xFFF5F5F5),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _noteService.getNotesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Aucune note à rechercher.'));
          }

          _searchResults = _filterNotes(snapshot.data!.docs);

          if (_searchResults.isEmpty) {
            return Center(child: Text('Aucun résultat pour "${_searchController.text}"'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final noteData = _searchResults[index].data() as Map<String, dynamic>;
              final noteId = _searchResults[index].id;
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