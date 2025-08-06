// lib/services/quiz_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> saveQuizResult(String noteId, String subject, int score, int totalQuestions) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // On utilise l'ID de la note comme ID du document pour éviter les doublons
    await _firestore.collection('quizResults').doc('${user.uid}_$noteId').set({
      'userId': user.uid,
      'noteId': noteId,
      'subject': subject,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': Timestamp.now(),
    });
  }
}