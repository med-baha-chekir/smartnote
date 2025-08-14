// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Stream<DocumentSnapshot> getUserDocumentStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.empty();
    return _firestore.collection('users').doc(user.uid).snapshots();
  }
  /// Met à jour la série d'étude de l'utilisateur et retourne la nouvelle valeur.
  Future<int> updateUserStudyStreak() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();
    
    int currentStreak = 0;
    
    // Date actuelle (sans les heures/minutes)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    if (userDoc.exists) {
      final data = userDoc.data()!;
      currentStreak = data['studyStreak'] ?? 0;
      final lastSeenTimestamp = data['lastSeen'] as Timestamp?;

      if (lastSeenTimestamp != null) {
        final lastSeenDate = lastSeenTimestamp.toDate();
        final lastSeen = DateTime(lastSeenDate.year, lastSeenDate.month, lastSeenDate.day);
        
        final difference = today.difference(lastSeen).inDays;

        if (difference == 1) {
          // L'utilisateur s'est connecté hier -> on continue la série
          currentStreak++;
        } else if (difference > 1) {
          // L'utilisateur a manqué un ou plusieurs jours -> on brise la série
          currentStreak = 1;
        }
        // Si difference == 0, on ne fait rien (connecté plus tôt aujourd'hui)
      } else {
        // C'est la première fois qu'on voit cet utilisateur
        currentStreak = 1;
      }
    } else {
      // Le document n'existe pas, c'est la toute première connexion
      currentStreak = 1;
    }

    // On met à jour la base de données avec la nouvelle série et la date actuelle
    await userDocRef.set({
      'studyStreak': currentStreak,
      'lastSeen': Timestamp.now(),
    }, SetOptions(merge: true)); // merge: true pour ne pas écraser d'autres champs

    return currentStreak;
  }
}