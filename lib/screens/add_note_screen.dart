// lib/screens/add_note_screen.dart

import 'package:flutter/material.dart';
import 'package:smartnote/services/note_service.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final NoteService _noteService = NoteService();

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
        title: const Text('Nouvelle Note'),
        actions: [
          // Bouton pour sauvegarder la note
          IconButton(
            tooltip: 'Enregistrer',
            icon: const Icon(Icons.save_outlined),
            onPressed: () {
              final title = _titleController.text;
              final content = _contentController.text;

              // On vérifie que le contenu n'est pas vide
              if (title.isNotEmpty || content.isNotEmpty) {
                // On appelle notre service pour enregistrer la note
                _noteService.addNote(title, content);
              }
              print('Titre: $title, Contenu: $content');
              // Après la sauvegarde, on ferme l'écran
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Champ pour le titre
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Titre',
                border: InputBorder.none, // Pas de bordure pour un look épuré
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Champ pour le contenu, qui prend tout l'espace restant
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Commencez à écrire votre note ici...',
                  border: InputBorder.none,
                ),
                maxLines: null, // Permet un nombre de lignes illimité
                expands: true, // Fait en sorte que le champ remplisse l'Expanded
              ),
            ),
          ],
        ),
      ),
    );
  }
}