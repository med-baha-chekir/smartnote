// lib/services/note_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- Import nécessaire

class NoteService {

final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(app: Firebase.app());
final FirebaseAuth _auth = FirebaseAuth.instanceFor(app: Firebase.app());
  
  // --- NOUVELLE VARIABLE POUR LES CLOUD FUNCTIONS ---
  // On récupère une instance de FirebaseFunctions.
  // Assurez-vous que la région 'us-central1' correspond à celle où votre fonction a été déployée.
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Récupère un flux de notes pour l'utilisateur actuellement connecté.
  Stream<QuerySnapshot> getNotesStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.empty(); // Renvoie un flux vide si personne n'est connecté
    }
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Récupère un seul document de note par son ID.
  Future<DocumentSnapshot> getNoteById(String noteId) {
    return _firestore.collection('notes').doc(noteId).get();
  }

  /// Ajoute une nouvelle note dans Firestore.
  Future<void> addNote(String title, String content) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print("Erreur: Utilisateur non connecté pour l'ajout.");
      return;
    }

    try {
      await _firestore.collection('notes').add({
        'title': title,
        'content': content,
        'createdAt': Timestamp.now(),
        'userId': user.uid,
      });
      print("Note ajoutée avec succès !");
    } catch (e) {
      print("Erreur lors de l'ajout de la note: $e");
    }
  }

  /// Met à jour une note existante.
  Future<void> updateNote(String noteId, String title, String content) {
    return _firestore.collection('notes').doc(noteId).update({
      'title': title,
      'content': content,
      'lastUpdatedAt': Timestamp.now(),
    });
  }

  /// Supprime une note.
  Future<void> deleteNote(String noteId) {
    return _firestore.collection('notes').doc(noteId).delete();
  }

  // --- NOUVELLE FONCTION POUR APPELER L'IA DE RÉSUMÉ ---

  /// Appelle la Cloud Function 'summarizeText' pour générer un résumé.
  /// Renvoie le résumé (String) en cas de succès.
  /// Renvoie un message d'erreur (String) en cas d'échec.
  Future<String> getSummary(String text) async {
    // On vérifie que le texte n'est pas vide pour ne pas faire un appel API inutile.
    if (text.trim().isEmpty) {
      return "Le contenu de la note est vide et ne peut pas être résumé.";
    }

    try {
      // On prépare l'appel à notre fonction déployée, nommée 'summarizeText'.
      final HttpsCallable callable = _functions.httpsCallable('summarizeText');
      
      // On exécute l'appel en envoyant le texte de la note en paramètre.
      final result = await callable.call<Map<String, dynamic>>({
        'text': text,
      });

      // On récupère le champ 'summary' de la réponse et on le retourne.
      return result.data['summary'] ?? 'Le résumé n\'a pas pu être généré.';

    } on FirebaseFunctionsException catch (e) {
      // Gère les erreurs spécifiques aux Cloud Functions (ex: permission refusée, etc.)
      print('Erreur de la Cloud Function: ${e.code} - ${e.message}');
      return "Erreur lors de la génération du résumé. Veuillez réessayer.";
    } catch (e) {
      // Gère toutes les autres erreurs (ex: problème de réseau).
      print("Erreur inconnue lors de l'appel à la Cloud Function: $e");
      return "Une erreur inattendue est survenue.";
    }
  }
}