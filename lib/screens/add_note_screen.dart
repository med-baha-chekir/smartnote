// lib/screens/add_note_screen.dart

import 'package:flutter/material.dart';
import 'package:smartnote/services/note_service.dart';

class AddNoteScreen extends StatefulWidget {
  final String? noteId;
  final String? initialTitle;
  bool _isLoading = false;   
  final String? initialContent;
  
  


  AddNoteScreen({
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
  bool _isLoading = false;

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
  // Dans _AddNoteScreenState

void _saveNote() async { // La fonction doit être 'async'
  if (_isLoading) return;

  // --- DÉBUT DU CHARGEMENT ---
  setState(() {
    _isLoading = true;
  });

  String title = _titleController.text.trim();
  final String content = _contentController.text.trim();
  String? subject; // On prépare une variable pour le sujet

  if (title.isEmpty && content.isNotEmpty) {
    // Si le titre est vide, on appelle l'IA !
    final analysis = await _noteService.analyzeNote(content);
    if (analysis != null) {
      title = analysis['title'] ?? '';
      subject = analysis['subject'];
    }
  }

  if (title.isEmpty && content.isEmpty) {
    Navigator.pop(context);
    return;
  }

  if (_isEditing) {
    // TODO: Gérer la mise à jour du sujet lors de l'édition
    await _noteService.updateNote(widget.noteId!, title, content);
  } else {
    await _noteService.addNote(title, content, subject: subject);
  }

  if (mounted) {
    Navigator.pop(context);
  }
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
  // Dans la classe _AddNoteScreenState

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: BackButton(
        // On désactive le bouton retour pendant le chargement
        onPressed: _isLoading ? null : () => Navigator.pop(context),
        color: Colors.black,
      ),
      actions: [
        // --- MODIFICATION ICI : Le bouton change d'apparence ---
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _isLoading
              // Si on charge, on affiche un indicateur de progression circulaire
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                )
              // Sinon, on affiche le bouton "Enregistrer" normal
              : IconButton(
                  tooltip: 'Enregistrer',
                  icon: Icon(Icons.check, color: Theme.of(context).primaryColor, size: 28),
                  onPressed: _saveNote,
                ),
        ),
      ],
    ),
    // --- MODIFICATION ICI : On désactive l'interface pendant le chargement ---
    body: AbsorbPointer(
      absorbing: _isLoading, // 'absorbing' est true quand _isLoading est true
      child: Opacity(
        opacity: _isLoading ? 0.5 : 1.0, // On rend l'UI semi-transparente
        child: Column(
          children: [
            // Le reste de votre UI est parfait et reste à l'intérieur
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
                    icon: const Icon(Icons.auto_awesome_outlined, size: 20),
                    label: const Text('Analyze and Summarize'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}