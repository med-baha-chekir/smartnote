// lib/screens/note_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/screens/add_note_screen.dart';
import 'package:smartnote/screens/quiz_screen.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/utils/snackbar_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteDetailScreen extends StatefulWidget {
  final String noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final NoteService _noteService = NoteService();
  late Future<DocumentSnapshot> _noteFuture;
  
  int _selectedTabIndex = 0;
  bool _isSummaryLoading = false;
  bool _isQuizLoading = false;

  @override
  void initState() {
    super.initState();
    _noteFuture = _noteService.getNoteById(widget.noteId);
  }

  // --- Fonctions de gestion d'état ---
  void _navigateToEditScreen(Map<String, dynamic> noteData) async {
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
    _refreshNoteData();
  }

  void _generateSummary(Map<String, dynamic> noteData) async {
    setState(() => _isSummaryLoading = true);
    await _noteService.getSummary(widget.noteId, noteData['content'] ?? '');
    _refreshNoteData();
  }

  void _generateQuiz(Map<String, dynamic> noteData) async {
    setState(() => _isQuizLoading = true);
    final quizResult = await _noteService.getQuiz(widget.noteId, noteData['content'] ?? '');
    
    if (mounted) {
      if (quizResult != null && quizResult.isNotEmpty) {
        _refreshNoteData();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizScreen(
              questions: quizResult,
              noteId: widget.noteId, // <-- ON PASSE L'ID DE LA NOTE ACTUELLE
              subject: noteData['subject'] ?? 'Général', // <-- ON PASSE LE SUJET ACTUEL
            ),
          ),
        );
        setState(() => _isQuizLoading = false);
      } else {
        SnackBarHelper.showError(context, 'Impossible de générer le quiz pour cette note.');
        setState(() => _isQuizLoading = false);
      }
    }
  }

  void _refreshNoteData() {
    if (mounted) {
      setState(() {
        _noteFuture = _noteService.getNoteById(widget.noteId);
        _isSummaryLoading = false;
        // _isQuizLoading n'est pas remis à false ici, car la navigation intervient après
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _noteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(backgroundColor: Colors.white, body: Center(child: Text('Note introuvable.')));
        }

        final noteData = snapshot.data!.data() as Map<String, dynamic>;
        final title = noteData['title'] ?? 'Note sans titre';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            title: Text(title, style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            actions: [
              if (noteData['pdfUrl'] != null && (noteData['pdfUrl'] as String).isNotEmpty)
                IconButton(
                  tooltip: 'Ouvrir le PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.black),
                  onPressed: () async {
                    try {
                      await launchUrl(Uri.parse(noteData['pdfUrl']), mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if(mounted) SnackBarHelper.showError(context, 'Impossible d\'ouvrir le fichier PDF.');
                    }
                  },
                ),
              IconButton(
                tooltip: 'Modifier la note',
                icon: const Icon(Icons.edit_outlined, color: Colors.black),
                onPressed: () => _navigateToEditScreen(noteData),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      _buildTabItem(context, 'Note complète', 0),
                      _buildTabItem(context, 'Résumé IA', 1),
                      _buildTabItem(context, 'Quiz IA', 2),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                  child: IndexedStack(
                    index: _selectedTabIndex,
                    children: [
                      _buildFullNoteView(noteData['content'] ?? 'Aucun contenu.'),
                      _buildSummaryView(noteData),
                      _buildQuizView(noteData),
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

  // --- Widgets de construction ---
  Widget _buildTabItem(BuildContext context, String text, int index) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2))] : [],
          ),
          child: Center(child: Text(text, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.black))),
        ),
      ),
    );
  }

  Widget _buildFullNoteView(String content) {
    return SingleChildScrollView(
      child: Text(content, style: const TextStyle(fontSize: 16, height: 1.6)),
    );
  }

  Widget _buildSummaryView(Map<String, dynamic> noteData) {
    final String? summary = noteData['summary'];
    if (_isSummaryLoading) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Génération du résumé...')]));
    }
    if (summary == null || summary.isEmpty) {
      return Center(child: ElevatedButton.icon(onPressed: () => _generateSummary(noteData), icon: const Icon(Icons.auto_awesome_outlined), label: const Text('Générer le résumé')));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.auto_awesome_outlined, color: Theme.of(context).primaryColor), const SizedBox(width: 8), const Text('Résumé généré par IA ✨', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)), child: Text(summary, style: const TextStyle(fontSize: 16, height: 1.6))),
        const SizedBox(height: 24),
        Center(child: TextButton.icon(onPressed: () => _generateSummary(noteData), icon: const Icon(Icons.refresh), label: const Text('Régénérer le résumé'))),
      ]),
    );
  }

  Widget _buildQuizView(Map<String, dynamic> noteData) {
    final dynamic quizData = noteData['quiz'];
    if (quizData == null || quizData is! List) {
      if (_isQuizLoading) return const Center(child: CircularProgressIndicator());
      return Center(child: ElevatedButton.icon(onPressed: () => _generateQuiz(noteData), icon: const Icon(Icons.quiz_outlined), label: const Text('Générer un Quiz')));
    }
    final List<Map<String, dynamic>> questions = List<Map<String, dynamic>>.from(quizData);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.psychology_outlined, color: Theme.of(context).primaryColor, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Quiz IA généré', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${questions.length} questions ont été générées', style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      questions: questions,
                      noteId: widget.noteId, // <-- AJOUTER L'ID DE LA NOTE
                      subject: noteData['subject'] ?? 'Général', // <-- AJOUTER LE SUJET
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Commencer le Quiz'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            Text('Temps estimé : ${questions.length * 0.5}-${questions.length} minutes', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Difficulté : Intermédiaire', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _isQuizLoading ? null : () => _generateQuiz(noteData),
              child: _isQuizLoading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Régénération en cours...'),
                      ],
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 8),
                        Text('Régénérer le Quiz'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}