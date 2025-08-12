// lib/screens/add_note_screen.dart

import 'package:flutter/material.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/utils/snackbar_helper.dart';

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
   String? _generatedSummary;
  List<Map<String, dynamic>>? _generatedQuiz;
  String? _generatedSubject;

  bool get _isEditing => widget.noteId != null;

  @override
  void initState() {
  super.initState();
  
  // On vérifie d'abord si on est en mode édition
  if (_isEditing) {
    _titleController.text = widget.initialTitle ?? '';
    _contentController.text = widget.initialContent ?? '';
  } 
  // SINON, on vérifie si un contenu initial a été passé (cas de l'OCR)
  else if (widget.initialContent != null) {
    _contentController.text = widget.initialContent!;
  }
}

  // --- LES FONCTIONS RESTENT LES MÊMES ---
  // Dans _AddNoteScreenState

void _saveNote() async {
  // Si on est déjà en train de sauvegarder, on ne fait rien pour éviter les double-clics
  if (_isLoading) return;

  setState(() { _isLoading = true; });

  String title = _titleController.text.trim();
  final String content = _contentController.text.trim();
  
  // On utilise directement les variables d'état qui ont pu être remplies par _analyzeAndSummarize
  String? subject = _generatedSubject; 
  String? summary = _generatedSummary;
  List<Map<String, dynamic>>? quiz = _generatedQuiz;

  // On vérifie si une analyse est nécessaire (titre vide et aucune analyse préalable)
  if (title.isEmpty && content.isNotEmpty && subject == null) {
    final analysis = await _noteService.analyzeNote(content);
    if (analysis != null) {
      title = analysis['title'] ?? '';
      subject = analysis['subject'];
      // On met à jour le contrôleur du titre pour que l'utilisateur le voie
      _titleController.text = title; 
    }
  }

  if (title.isEmpty && content.isEmpty) {
    if (mounted) Navigator.pop(context);
    return;
  }

  // On appelle la bonne méthode de sauvegarde en passant toutes les données
  if (_isEditing) {
    await _noteService.updateNote(
      widget.noteId!,
      title,
      content,
      subject: subject,
      summary: summary,
      quiz: quiz,
    );
  } else {
    await _noteService.addNote(
      title,
      content,
      subject: subject,
      summary: summary,
      quiz: quiz,
    );
  }

  if (mounted) Navigator.pop(context);
}

    void _analyzeAndSummarizeAndSave() async {
    // Si on est déjà en train de charger, on ne fait rien
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      SnackBarHelper.showError(context, 'Le contenu est vide pour l\'analyse.');
      setState(() => _isLoading = false);
      return;
    }

    // 1. On appelle l'IA pour enrichir la note
    final results = await _noteService.analyzeAndEnrichNote(content);

    if (!mounted) return;

    if (results != null) {
      // 2. On prépare TOUTES les données à sauvegarder
      final Map<String, dynamic> dataToSave = {
        'title': results['title'] ?? 'Titre généré par IA',
        'content': content, // On garde le contenu original
        'subject': results['subject'],
        'summary': results['summary'],
        'quiz': results['quiz'],
      };

      // 3. On sauvegarde les données (création ou mise à jour)
      if (_isEditing) {
        await _noteService.updateNoteFromMap(widget.noteId!, dataToSave);
      } else {
        await _noteService.addNoteFromMap(dataToSave);
      }
      
      // 4. On quitte l'écran pour revenir à la liste
      Navigator.pop(context);

    } else {
      // Si l'analyse a échoué, on arrête le chargement et on affiche une erreur
      setState(() => _isLoading = false);
      SnackBarHelper.showError(context, 'L\'analyse a échoué.');
    }
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
                    onPressed: _analyzeAndSummarizeAndSave,
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