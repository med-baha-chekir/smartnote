
import 'dart:async'; // Pour StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/services/auth_service.dart';
import 'package:smartnote/services/note_service.dart'; 

// --- ON TRANSFORME L'ÉCRAN EN STATEFULWIDGET ---
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final NoteService _noteService = NoteService();
  final AuthService _authService = AuthService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  StreamSubscription? _userSubscription;

  // Abonnements pour l'écoute en temps réel
  StreamSubscription? _notesSubscription;
  StreamSubscription? _quizResultsSubscription;
  
  // Variables pour stocker nos données
  int _notesCount = 0;
  int _summariesCount = 0;
  int _quizzesCount = 0;
  // TODO: Logique pour la série d'étude
  int _studyStreak = 0; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenToDataChanges();
  }

  void _listenToDataChanges() {
    // S'abonner aux notes
    _notesSubscription = _noteService.getNotesStream().listen((snapshot) {
      int summaryCount = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['summary'] != null && (data['summary'] as String).isNotEmpty) {
          summaryCount++;
        }
      }
      if (mounted) {
        setState(() {
          _notesCount = snapshot.docs.length;
          _summariesCount = summaryCount;
          _isLoading = false;
        });
      }
    });

    // S'abonner aux résultats de quiz
    _quizResultsSubscription = _noteService.getQuizResultsStream().listen((snapshot) {
      if (mounted) {
        setState(() {
          _quizzesCount = snapshot.docs.length;
        });
      }
    });
    _userSubscription = _noteService.getUserDocumentStream().listen((snapshot) {
    if (mounted && snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      setState(() {
        _studyStreak = data['studyStreak'] ?? 0;
      });
    }
  });
  }

  @override
  void dispose() {
    _notesSubscription?.cancel();
    _quizResultsSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final String email = _currentUser?.email ?? 'Pas d\'email';
    final String displayName = _currentUser?.displayName ?? 'Nouvel Utilisateur';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        title: const Text('Mon Profil', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildUserCard(displayName, email),
            const SizedBox(height: 2),

            const Text('Vos Statistiques', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // --- ON UTILISE LES VRAIES DONNÉES ICI ---
                _buildStatCard(Icons.article_outlined, _notesCount.toString(), 'Notes Créées', Colors.blue),
                _buildStatCard(Icons.auto_awesome_outlined, _summariesCount.toString(), 'Résumés IA', Colors.orange),
                _buildStatCard(Icons.quiz_outlined, _quizzesCount.toString(), 'Quiz Complétés', Colors.green),
                _buildStatCard(Icons.local_fire_department_outlined, '$_studyStreak jours', 'Série d\'Étude', Colors.red),
              ],
            ),
            

          // --- SECTION PARAMÈTRES ---
         // _buildSectionTitle('Paramètres'),
          //_buildSettingsCard(
          //  children: [
          //    _buildSettingsItem(Icons.dark_mode_outlined, 'Thème Sombre', trailing: Switch(value: false, onChanged: (val) {})),
          ///    _buildSettingsItem(Icons.notifications_outlined, 'Notifications', onTap: () {}),
          //  ],
          //),
          //const SizedBox(height: 16),
          //const Divider(height: 1, indent: 16, endIndent: 16),

          _buildSettingsItem(
                Icons.logout, 
                'Se Déconnecter', 
                color: Colors.red, // On le met en rouge pour indiquer une action finale
                onTap: () {
                  // On appelle la fonction signOut de notre service d'authentification
                  _authService.signOut();
                  // Le AuthGate s'occupera de la redirection vers LoginScreen
                }
              ),
          const SizedBox(height: 80)
          ],
        
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCTION POUR UN DESIGN PROPRE ---

  Widget _buildUserCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.grey.shade200,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, {Widget? trailing, VoidCallback? onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: trailing,
      onTap: onTap,
    );
  }
  
}