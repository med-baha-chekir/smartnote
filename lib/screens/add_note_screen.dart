// lib/screens/add_note_screen.dart

import 'package:flutter/material.dart';
import 'package:smartnote/services/note_service.dart';

class AddNoteScreen extends StatefulWidget {
  final String? noteId;
  final String? initialTitle;
  final String? initialContent;

  const AddNoteScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final NoteService _noteService = NoteService();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool get _isEditing => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _titleController.text = widget.initialTitle ?? '';
      _contentController.text = widget.initialContent ?? '';
    }
  }

  // --- LES FONCTIONS RESTENT LES MÊMES ---
  void _saveNote() {
    final title = _titleController.text;
    final content = _contentController.text;
    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }
    if (_isEditing) {
      _noteService.updateNote(widget.noteId!, title, content);
    } else {
      _noteService.addNote(title, content);
    }
    Navigator.pop(context);
  }

  void _analyzeAndSummarize() {
    // TODO: Connecter à la Cloud Function pour l'analyse
    print('Analyse et résumé demandés...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité d\'analyse bientôt disponible !')),
    );
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // --- LE BUILD EST MODIFIÉ POUR LE NOUVEAU DESIGN ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black, onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            tooltip: 'Enregistrer',
            icon: Icon(Icons.check, color: Theme.of(context).primaryColor, size: 28),
            onPressed: _saveNote, // La coche appelle la sauvegarde
          ),
        ],
      ),
      body: Column( // On divise l'écran en 2 parties
        children: [
          // 1. La partie éditable qui prend tout l'espace disponible
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'titre de votre note...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: 'Commencez à écrire ou collez votre texte ici...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    maxLines: null,
                  ),
                ],
              ),
            ),
          ),
          // 2. La barre d'outils en bas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.format_bold)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.format_italic)),
                    IconButton(onPressed: () {}, icon: const Icon(Icons.format_list_bulleted)),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _analyzeAndSummarize,
                  icon: const Icon(Icons.auto_awesome_outlined, size: 20, color: Colors.white),
                  label: const Text('Analyze and Summarize', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}