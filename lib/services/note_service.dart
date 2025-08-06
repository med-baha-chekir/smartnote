// lib/services/note_service.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'package:firebase_storage/firebase_storage.dart';

class NoteService {

final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(app: Firebase.app());
final FirebaseAuth _auth = FirebaseAuth.instanceFor(app: Firebase.app());
  
  // --- NOUVELLE VARIABLE POUR LES CLOUD FUNCTIONS ---
  // On récupère une instance de FirebaseFunctions.
  // Assurez-vous que la région 'us-central1' correspond à celle où votre fonction a été déployée.
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
   final FirebaseStorage _storage = FirebaseStorage.instance;

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
  // Dans note_service.dart

// On modifie la signature de la fonction
Future<void> addNote(String title, String content, {String? subject, Timestamp? createdAt, String? summary}) async {
  final User? user = _auth.currentUser;
  if (user == null) {
    print("Erreur: Utilisateur non connecté.");
    return;
  }

  try {
    // On utilise une Map pour construire les données, c'est plus propre
    final Map<String, dynamic> noteData = {
      'title': title,
      'content': content,
      'createdAt': createdAt ?? Timestamp.now(),
      'userId': user.uid,
    };

    // On ajoute les champs optionnels seulement s'ils ne sont pas null
    if (subject != null) {
      noteData['subject'] = subject;
    }
    if (summary != null) {
      noteData['summary'] = summary;
    }
    
    // On ajoute le document avec toutes les données
    await _firestore.collection('notes').add(noteData);

    print("Note ajoutée/restaurée avec succès !");
  } catch (e) {
    print("Erreur lors de l'ajout/restauration de la note: $e");
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
  Future<String> getSummary(String noteId, String text) async {
    if (text.trim().isEmpty) {
      return "Le contenu de la note est vide.";
    }

    try {
      final HttpsCallable callable = _functions.httpsCallable('summarizeText');
      final result = await callable.call<Map<String, dynamic>>({'text': text});
      final summary = result.data['summary'] ?? 'Aucun résumé n\'a pu être généré.';

      await _firestore.collection('notes').doc(noteId).update({
        'summary': summary,
        'summaryGeneratedAt': Timestamp.now(),
      });
      
      // Chemin de succès : on retourne le résumé
      return summary;

    } on FirebaseFunctionsException catch (e) {
      print('Erreur de la Cloud Function: ${e.code} - ${e.message}');
      // --- CORRECTION ICI ---
      // Chemin d'erreur 1 : on retourne un message d'erreur
      return "Erreur lors de la génération du résumé. Veuillez réessayer.";

    } catch (e) {
      print("Erreur inconnue lors de l'appel à la Cloud Function: $e");
      // --- CORRECTION ICI ---
      // Chemin d'erreur 2 : on retourne un message d'erreur
      return "Une erreur inattendue est survenue.";
    }
  } 
  Future<Map<String, dynamic>?> analyzeNote(String text) async {
  if (text.trim().length < 50) return null; // On n'analyse pas si le texte est trop court
  try {
    final callable = _functions.httpsCallable('analyzeNote');
    final result = await callable.call<Map<String, dynamic>>({'text': text});
    return result.data;
  } catch (e) {
    print("Erreur lors de l'analyse de la note: $e");
    return null;
  }
}
Future<void> uploadPdf(File file) async {
  final User? user = _auth.currentUser;
  if (user == null) return;
  try {
    final String fileName = file.path.split('/').last;
    final String filePath = 'uploads/${user.uid}/$fileName';
    final ref = _storage.ref().child(filePath);

    // 1. Uploader le fichier
    final uploadTask = await ref.putFile(file);
    
    // 2. Récupérer l'URL de téléchargement
    final String downloadUrl = await uploadTask.ref.getDownloadURL();

    final HttpsCallable callable = _functions.httpsCallable('processPdfFromUrl');
    await callable.call<void>({
      'url': downloadUrl,
      'fileName': fileName, // On passe le nom du fichier
    });

    print('Appel à processPdfFromUrl réussi.');
    // Optionnel : on peut supprimer le fichier de Storage ici si la fonction ne le fait pas
    // await ref.delete();

  } catch (e) {
    print("Erreur dans le processus d'upload et de traitement du PDF: $e");
  }
}
// --- NOUVELLE FONCTION POUR OBTENIR LE QUIZ ---
Future<List<Map<String, dynamic>>?> getQuiz(String noteId, String text) async {
  if (text.trim().length < 50) {
    print("Texte trop court pour générer un quiz.");
    return null;
  }
  try {
    final HttpsCallable callable = _functions.httpsCallable('generateQuiz');
    final result = await callable.call<Map<String, dynamic>>({'text': text});
    
    // --- DÉBUT DE LA CORRECTION ---

    // 1. On récupère les données brutes
    final dynamic rawQuizData = result.data['quiz'];

    // 2. On s'assure que c'est bien une liste
    if (rawQuizData is List) {
      // 3. On convertit la liste en notre type désiré de manière sûre
      final List<Map<String, dynamic>> quiz = rawQuizData.map<Map<String, dynamic>>((item) {
        // On s'assure que chaque élément de la liste est bien une Map
        if (item is Map) {
          // On convertit les clés et les valeurs
          return Map<String, dynamic>.from(item);
        }
        // Si un élément n'est pas une Map, on retourne une map vide pour éviter un crash
        return <String, dynamic>{};
      }).toList();

      // On stocke le tableau de questions dans Firestore
      await _firestore.collection('notes').doc(noteId).update({
        'quiz': quiz,
      });

      return quiz;
    }

    // Si les données ne sont pas une liste, on considère que c'est une erreur.
    return null;

    // --- FIN DE LA CORRECTION ---

  } catch (e) {
    print("Erreur lors de l'appel à la fonction getQuiz: $e");
    return null;
  } 
}

  Stream<QuerySnapshot> searchNotes(String query) {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    
    // Si la recherche est vide, on retourne toutes les notes de l'utilisateur
    if (query.isEmpty) {
      return getNotesStream();
    }

    // Firestore ne permet pas de faire une recherche "contient" directement.
    // Cette astuce permet de rechercher des titres qui COMMENCENT par la chaîne de recherche.
    // C'est une recherche par préfixe.
    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .where('title', isGreaterThanOrEqualTo: query)
        .where('title', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots();
  }
  /// Récupère un flux de notes filtrées par matière (subject).
  Stream<QuerySnapshot> getNotesStreamBySubject(String subject) {
    final User? user = _auth.currentUser;
    if (user == null) return Stream.empty();

    return _firestore
        .collection('notes')
        .where('userId', isEqualTo: user.uid)
        .where('subject', isEqualTo: subject) // Le filtre magique
        .snapshots();
  }

  // --- LA NOUVELLE FONCTION DOIT ÊTRE ICI ---


  Stream<QuerySnapshot> getQuizResultsStream() {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    // --- ON AJOUTE LE FILTRE PAR UTILISATEUR ---
    return _firestore
        .collection('quizResults')
        .where('userId', isEqualTo: user.uid) // <-- LA LIGNE MAGIQUE
        .snapshots();
  }
    Future<QuerySnapshot> getAllQuizResultsFuture() async {
  final User? user = _auth.currentUser;
  if (user == null) {
    // On retourne un Future qui se résout avec un QuerySnapshot vide.
    // Pour cela, on fait une requête impossible qui ne retournera jamais de résultats.
    return _firestore.collection('quizResults').where('userId', isEqualTo: 'user-is-not-logged-in').get();
  }
  return _firestore
      .collection('quizResults')
      .where('userId', isEqualTo: user.uid)
      .get(); // .get() pour un Future, .snapshots() pour
}
}
