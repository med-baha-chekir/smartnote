// lib/screens/note_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/services/note_service.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NoteService _noteService = NoteService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNoteData();
  }

  // Fonction pour charger les données de la note
  Future<void> _loadNoteData() async {
    final noteSnapshot = await _noteService.getNoteById(widget.noteId);
    if (noteSnapshot.exists) {
      final noteData = noteSnapshot.data() as Map<String, dynamic>;
      _titleController.text = noteData['title'] ?? '';
      _contentController.text = noteData['content'] ?? '';
    }
  }

  // Fonctions pour les actions
  void _updateNote() {
    _noteService.updateNote(
      widget.noteId,
      _titleController.text,
      _contentController.text,
    );
    Navigator.pop(context);
  }

  void _deleteNote() {
    // On peut ajouter une boîte de dialogue de confirmation pour la sécurité
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette note ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Ferme la boîte de dialogue
              _noteService.deleteNote(widget.noteId);
              Navigator.pop(context); // Revient à l'écran d'accueil
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier la Note'),
        actions: [
          IconButton(tooltip: 'Supprimer', icon: const Icon(Icons.delete_outline), onPressed: _deleteNote),
          IconButton(tooltip: 'Enregistrer', icon: const Icon(Icons.save_outlined), onPressed: _updateNote),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(hintText: 'Titre', border: InputBorder.none), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Expanded(child: TextField(controller: _contentController, decoration: const InputDecoration(hintText: 'Contenu...', border: InputBorder.none), maxLines: null, expands: true)),
          ],
        ),
      ),
    );
  }
}