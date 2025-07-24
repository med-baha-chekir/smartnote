// lib/services/note_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Récupère un flux (Stream) de notes pour l'utilisateur actuellement connecté.
  /// Le flux se mettra à jour automatiquement si les données changent dans Firestore.

 Stream<QuerySnapshot> getNotesStream() {
  final User? user = _auth.currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  return _firestore
      .collection('notes')
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots();
}
// --- NOUVELLE FONCTION POUR AJOUTER UNE NOTE ---
  Future<void> addNote(String title, String content) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      // Si l'utilisateur n'est pas connecté, on ne fait rien.
      print("Erreur: Utilisateur non connecté.");
      return;
    }

    try {
      await _firestore.collection('notes').add({
        'title': title,
        'content': content,
        'createdAt': Timestamp.now(), // La date et l'heure actuelles
        'userId': user.uid, // L'ID de l'utilisateur qui a créé la note
      });
      print("Note ajoutée avec succès !");
    } catch (e) {
      print("Erreur lors de l'ajout de la note: $e");
    }
  }
  Future<DocumentSnapshot> getNoteById(String noteId) {
    return _firestore.collection('notes').doc(noteId).get();
  }

  /// Met à jour une note existante.
  Future<void> updateNote(String noteId, String title, String content) {
    return _firestore.collection('notes').doc(noteId).update({
      'title': title,
      'content': content,
      // On pourrait aussi mettre à jour une date de modification ici
      'lastUpdatedAt': Timestamp.now(),
    });
  }

  /// Supprime une note.
  Future<void> deleteNote(String noteId) {
    return _firestore.collection('notes').doc(noteId).delete();
  }

  // TODO: Ajouter les fonctions pour créer, mettre à jour et supprimer des notes
}