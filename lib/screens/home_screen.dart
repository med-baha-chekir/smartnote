// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/screens/add_note_screen.dart';
import 'package:smartnote/services/auth_service.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/widgets/note_card.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:smartnote/screens/note_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- DÉCLARATION CORRECTE DES SERVICES (UNE SEULE FOIS) ---
  final AuthService _authService = AuthService();
  final NoteService _noteService = NoteService();

  // --- VARIABLES D'ÉTAT POUR L'UI ---
  int _selectedIndex = 0;
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Gérer la navigation pour les autres pages
  }

  void _navigateToAddNote() {
    // On ferme le menu avant de naviguer
    if (_isMenuOpen) {
      _toggleMenu();
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddNoteScreen()),
    );
  }
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes Notes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 28, color: Colors.black),
            onPressed: () { /* TODO: Naviguer vers la page de recherche */ },
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.black),
            onPressed: () {
              // On utilise l'instance de service déclarée en haut
              _authService.signOut();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Le contenu principal : la liste des notes
          StreamBuilder<QuerySnapshot>(
            stream: _noteService.getNotesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "Vous n'avez pas encore de notes.\nCliquez sur '+' pour commencer !",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              final notes = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: notes.length,
                itemBuilder: (context, index) {
                  final noteData = notes[index].data() as Map<String, dynamic>;
                  final timestamp = noteData['createdAt'] as Timestamp;
                  final date = timestamp.toDate();
                  // On utilise un format de date relatif (ex: 'hier', 'il y a 2 heures')
                  // C'est plus complexe, donc pour l'instant, utilisons un format simple.
                  final formattedDate = DateFormat('dd MMMM yyyy, HH:mm', 'fr_FR').format(date);
                  return NoteCard(
                    title: noteData['title'] ?? '',
                    previewContent: noteData['content'] ?? 'Aucun contenu',
                    date: formattedDate,
                    subject: noteData['subject'] ?? 'Général', // On anticipe un futur champ 'subject'
                    onTap: () {
                      final noteId = notes[index].id; // On récupère l'ID du document
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          // On passe l'ID à l'écran de détail
                          builder: (context) => NoteDetailScreen(noteId: noteId),
                        ),
                      );
                      print('Note ${notes[index].id} cliquée !');
                    },
                  );
                },
              );
            },
          ),

          // --- SECTION DU MENU FLOTTANT ---
          

          if (_isMenuOpen)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // S'adapte à la taille du contenu
                  children: [
                    _buildMenuItem(Icons.edit_outlined, 'Nouvelle Note', 'Ouvre l\'éditeur de texte', _navigateToAddNote),
                    const Divider(),
                    _buildMenuItem(Icons.picture_as_pdf_outlined, 'Importer un PDF', 'Extrait le texte d\'un fichier PDF', () {}),
                    const Divider(),
                    _buildMenuItem(Icons.camera_alt_outlined, 'Scanner un document', 'Ouvre l\'appareil photo pour l\'OCR', () {}),
                  ],
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMenu,
        child: Icon(_isMenuOpen ? Icons.close : Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 'Accueil', 0),
            _buildNavItem(Icons.school, 'Réviser', 1),
            const SizedBox(width: 40),
            _buildNavItem(Icons.search, 'Rechercher', 2),
            _buildNavItem(Icons.person, 'Profil', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey)),
      onTap: onTap,
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}