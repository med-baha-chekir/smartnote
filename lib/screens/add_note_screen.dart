// lib/screens/add_note_screen.dart

import 'package:flutter/material.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/utils/app_colors.dart';
import 'package:smartnote/utils/snackbar_helper.dart';

class AddNoteScreen extends StatefulWidget {
  final String? noteId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialSubject; // On ajoute le sujet initial

  const AddNoteScreen({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
    this.initialSubject,
  });

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final NoteService _noteService = NoteService();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  bool _isLoading = false;
  String _selectedSubject = 'Général'; // Variable d'état pour le sujet
  
  // Données générées par l'IA
  Map<String, dynamic> _iaData = {};

  bool get _isEditing => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
    
    // On initialise le sujet sélectionné, en priorité celui de la note
    if (widget.initialSubject != null) {
      _selectedSubject = widget.initialSubject!;
    }
  }

  /// Sauvegarde la note (appelé par la coche)
  void _saveNote() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    String title = _titleController.text.trim();
    final String content = _contentController.text.trim();

    // Si le titre est vide mais pas le contenu, on demande une analyse simple
    if (title.isEmpty && content.isNotEmpty) {
      final analysis = await _noteService.analyzeNote(content);
      if (analysis != null) {
        title = analysis['title'] ?? '';
        _titleController.text = title; // On met à jour l'UI
        // L'IA suggère un sujet, mais le choix de l'utilisateur a la priorité
        _selectedSubject = analysis['subject'] ?? _selectedSubject;
      }
    }

    if (title.isEmpty && content.isEmpty) {
      if (mounted) Navigator.pop(context);
      return;
    }
    
    // On fusionne les données de l'IA avec les données de l'utilisateur
    final Map<String, dynamic> dataToSave = {
      'title': title,
      'content': content,
      'subject': _selectedSubject, // Le choix de l'utilisateur est la source de vérité
      'summary': _iaData['summary'],
      'quiz': _iaData['quiz'],
    };

    if (_isEditing) {
      await _noteService.updateNoteFromMap(widget.noteId!, dataToSave);
    } else {
      await _noteService.addNoteFromMap(dataToSave);
    }
    
    if (mounted) Navigator.pop(context);
  }

  /// Analyse, sauvegarde et quitte l'écran
  void _analyzeAndSummarizeAndSave() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      SnackBarHelper.showError(context, 'Le contenu est vide pour l\'analyse.');
      setState(() => _isLoading = false);
      return;
    }

    final results = await _noteService.analyzeAndEnrichNote(content);

    if (!mounted) return;
    if (results != null) {
      final dataToSave = {
        'title': results['title'] ?? 'Titre généré par IA',
        'content': content,
        'subject': results['subject'] ?? 'Général',
        'summary': results['summary'],
        'quiz': results['quiz'],
      };
      if (_isEditing) {
        await _noteService.updateNoteFromMap(widget.noteId!, dataToSave);
      } else {
        await _noteService.addNoteFromMap(dataToSave);
      }
      Navigator.pop(context);
    } else {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(onPressed: _isLoading ? null : () => Navigator.pop(context), color: Colors.black),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3)))
                : IconButton(
                    tooltip: 'Enregistrer',
                    icon: Icon(Icons.check, color: Theme.of(context).primaryColor, size: 28),
                    onPressed: _saveNote,
                  ),
          ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: _isLoading,
        child: Opacity(
          opacity: _isLoading ? 0.5 : 1.0,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView(
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                            hintText: 'Titre de votre note...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 24, color: Colors.grey)),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      // --- SÉLECTEUR DE SUJET ---
                      DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        items: AppColors.availableSubjects.map((String subject) {
                          return DropdownMenuItem<String>(value: subject, child: Text(subject));
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) setState(() => _selectedSubject = newValue);
                        },
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.category_outlined, color: Colors.grey),
                        ),
                      ),
                      const Divider(),
                      TextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                            hintText: 'Commencez à écrire ou collez votre texte ici...',
                            border: InputBorder.none,
                            hintStyle: TextStyle(fontSize: 16, color: Colors.grey)),
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
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _analyzeAndSummarizeAndSave,
                      icon: _isLoading
                          ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : const Icon(Icons.auto_awesome_outlined, size: 20),
                      label: Text(_isLoading ? 'Analyse en cours...' : 'Analyze and Summarize'),
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