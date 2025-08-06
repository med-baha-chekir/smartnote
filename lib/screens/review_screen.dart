// lib/screens/review_screen.dart

import 'dart:async'; // Nécessaire pour StreamSubscription

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/screens/subject_detail_screen.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/utils/app_colors.dart';

// Modèle pour stocker les stats
class SubjectStats {
  int summaryCount = 0;
  int quizCount = 0;
  double progress = 0.0;
}

// L'écran est un StatefulWidget pour gérer les abonnements
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final NoteService _noteService = NoteService();

  // Abonnements pour l'écoute en temps réel
  StreamSubscription? _notesSubscription;
  StreamSubscription? _quizResultsSubscription;

  // Listes locales pour stocker les données à jour
  List<QueryDocumentSnapshot> _allNotes = [];
  List<QueryDocumentSnapshot> _quizResults = [];
  bool _isLoading = true;

  // Map pour stocker les stats calculées
  Map<String, SubjectStats> _statsBySubject = {};

  @override
  void initState() {
    super.initState();
    _listenToDataChanges();
  }

  /// S'abonne aux deux flux et recalcule tout à chaque mise à jour.
  void _listenToDataChanges() {
    _notesSubscription = _noteService.getNotesStream().listen((notesSnapshot) {
      if (mounted) {
        _allNotes = notesSnapshot.docs;
        _isLoading = false;
        _processAllData(); // Recalculer quand les notes changent
      }
    });

    _quizResultsSubscription = _noteService.getQuizResultsStream().listen((resultsSnapshot) {
      if (mounted) {
        _quizResults = resultsSnapshot.docs;
        _processAllData(); // Recalculer quand les résultats de quiz changent
      }
    });
  }

  /// Fonction centrale qui fait tous les calculs et appelle setState une seule fois.
  // DANS _ReviewScreenState

void _processAllData() {
   print('--- DÉBUT DU CALCUL ---');
  print('Nombre total de notes en mémoire: ${_allNotes.length}');
  print('Nombre total de résultats de quiz en mémoire: ${_quizResults.length}');
  final Map<String, SubjectStats> newStats = {};

  // --- ÉTAPE 1: La collection 'notes' est notre seule source de vérité pour les matières ---
  // On ne parcourt que les notes pour découvrir quelles matières doivent exister.
  for (var note in _allNotes) {
    final data = note.data() as Map<String, dynamic>;
    final subject = data['subject'] as String? ?? 'Général';

    // On initialise la matière si on ne l'a jamais vue
    newStats.putIfAbsent(subject, () => SubjectStats());

    // On compte les résumés pour cette matière
    if (data['summary'] is String && (data['summary'] as String).isNotEmpty) {
      newStats[subject]!.summaryCount++;
    }
    print('Étape 1 - Matières trouvées à partir des notes: ${newStats.keys.toList()}');
  }

  // --- ÉTAPE 2: Maintenant, pour chaque matière qui EXISTE, on va chercher les quiz associés ---
  newStats.forEach((subject, stats) {
    print('--- Calcul pour la matière: $subject ---');
    int totalScore = 0;
    int totalPossibleScore = 0;

    // On trouve tous les résultats de quiz qui correspondent à cette matière
    final relevantResults = _quizResults.where((r) {
      final data = r.data();
      if (data is Map<String, dynamic>) {
        return (data['subject'] as String? ?? 'Général') == subject;
      }
      return false;
    });

    // Le nombre de quiz pour cette matière est le nombre de résultats trouvés
    stats.quizCount = relevantResults.length;
    print('Nombre de résultats de quiz trouvés pour "$subject": ${stats.quizCount}');
    // On calcule la progression en se basant sur ces résultats
    for (var result in relevantResults) {
      final resultData = result.data() as Map<String, dynamic>;
      totalScore += (resultData['score'] ?? 0) as int;
      totalPossibleScore += (resultData['totalQuestions'] ?? 0) as int;
    }
    print('Score total pour "$subject": $totalScore / $totalPossibleScore');

    if (totalPossibleScore > 0) {
      stats.progress = totalScore / totalPossibleScore;
       print('Progression pour "$subject": ${stats.progress}');
    } else {
      stats.progress = 0.0;
    }
    print('------------------------------------');  
  });

  // On met à jour l'état final
  setState(() {
    _statsBySubject = newStats;
  });
  print('--- FIN DU CALCUL, MISE À JOUR DE L\'UI ---');
}

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _quizResultsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(backgroundColor: Colors.white, body: const Center(child: CircularProgressIndicator()));
    }
    if (_allNotes.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text('My Review Space', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28))),
        body: const Center(child: Text('Aucune note à réviser.')));
    }

    final subjects = _statsBySubject.keys.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Review Space', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final subjectStats = _statsBySubject[subject] ?? SubjectStats();
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SubjectDetailScreen(subject: subject))),
            child: _buildSubjectCard(subject, subjectStats, AppColors.getColorForSubject(subject)),
          );
        },
      ),
    );
  }

  Widget _buildSubjectCard(String title, SubjectStats stats, Color color) {
    return Card(
      color: color,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: stats.progress,
                      minHeight: 8,
                      backgroundColor: Colors.black.withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(stats.progress * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(Icons.psychology_outlined, '${stats.quizCount} Quizzes'),
                const SizedBox(width: 24),
                _buildStatItem(Icons.summarize_outlined, '${stats.summaryCount} Summaries'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black.withOpacity(0.6)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.black.withOpacity(0.8))),
      ],
    );
  }
}