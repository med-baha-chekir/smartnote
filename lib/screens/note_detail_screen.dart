// lib/screens/note_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/screens/add_note_screen.dart'; // Importer AddNoteScreen pour la modification

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NoteService _noteService = NoteService();
  int _selectedTabIndex = 0; // 0: Note, 1: Résumé, 2: Quiz
  
  // On utilise un FutureBuilder pour charger les données une seule fois
  late Future<DocumentSnapshot> _noteFuture;

  @override
  void initState() {
    super.initState();
    _noteFuture = _noteService.getNoteById(widget.noteId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _noteFuture,
      builder: (context, snapshot) {
        // Gérer les états de chargement et d'erreur
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(body: Center(child: Text('Impossible de charger la note.')));
        }

        // Si les données sont chargées, on récupère le titre
        final noteData = snapshot.data!.data() as Map<String, dynamic>;
        final title = noteData['title'] ?? 'Note sans titre';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)),
            actions: [
              // --- BOUTON POUR MODIFIER ---
              // Dans le FutureBuilder, à l'intérieur de l'AppBar
            IconButton(
              tooltip: 'Modifier la note',
              icon: const Icon(Icons.edit_outlined, color: Colors.black),
              onPressed: () {
                // On appelle notre nouvelle fonction qui gère le rafraîchissement
                final noteData = snapshot.data!.data() as Map<String, dynamic>;
                _navigateToEditScreen(noteData);
              },
            ),
            ],
          ),
          body: Column(
            children: [
              // --- LA BARRE D'ONGLETS ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _buildTabItem(context, 'Note complète', 0),
                      _buildTabItem(context, 'Résumé IA', 1),
                      _buildTabItem(context, 'Quiz IA', 2),
                    ],
                  ),
                ),
              ),

              // --- LE CONTENU AFFICHÉ SOUS LES ONGLETS ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  // On utilise IndexedStack pour garder l'état de chaque page des onglets
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      // Page 0: Note Complète
                      _buildFullNoteView(noteData['content'] ?? 'Aucun contenu.'),
                      // Page 1: Résumé IA
                      _buildSummaryView(), // TODO: Implémenter la vue du résumé
                      // Page 2: Quiz IA
                      _buildQuizView(), // TODO: Implémenter la vue du quiz
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGETS DE CONSTRUCTION ---

  Widget _buildTabItem(BuildContext context, String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))]
                : [],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullNoteView(String content) {
    return SingleChildScrollView(
      child: Text(
        content,
        style: const TextStyle(fontSize: 16, height: 1.6), // Interligne amélioré pour la lisibilité
      ),
    );
  }

  Widget _buildSummaryView() {
    // Vue temporaire pour le résumé
    return const Center(child: Text("La fonctionnalité de résumé IA sera bientôt disponible.", textAlign: TextAlign.center));
  }

  Widget _buildQuizView() {
    // Vue temporaire pour le quiz
    return const Center(child: Text("La fonctionnalité de quiz IA sera bientôt disponible.", textAlign: TextAlign.center));
  }
  // Dans _NoteDetailScreenState

void _navigateToEditScreen(Map<String, dynamic> noteData) async {
  // On utilise 'await' ici. Le code va attendre que l'écran d'édition soit fermé.
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddNoteScreen(
        noteId: widget.noteId,
        initialTitle: noteData['title'],
        initialContent: noteData['content'],
      ),
    ),
  );

  // --- LE RAFRAÎCHISSEMENT MAGIQUE ---
  // Une fois que l'on revient de l'écran d'édition, ce code s'exécute.
  // On force le rechargement des données et on met à jour l'interface.
  setState(() {
    _noteFuture = _noteService.getNoteById(widget.noteId);
  });
}
}