// lib/screens/home_screen.dart

import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:smartnote/screens/add_note_screen.dart';
import 'package:smartnote/screens/note_detail_screen.dart';
import 'package:smartnote/services/auth_service.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/widgets/note_card.dart';
import 'package:smartnote/screens/search_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final NoteService _noteService = NoteService();
  QueryDocumentSnapshot? _lastDeletedNote;

  int _selectedIndex = 0;
  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('fr_FR', null);
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _navigateToAddNote() {
    if (_isMenuOpen) _toggleMenu();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNoteScreen()),
    );
  }

  void _pickAndUploadPdf() async {
    if (_isMenuOpen) _toggleMenu();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import du PDF en cours...')),
      );
      await _noteService.uploadPdf(file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF importé ! La nouvelle note apparaîtra bientôt.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Permet au body de s'étendre derrière la nav bar
      backgroundColor: Colors.transparent,
      appBar: AppBar(

        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Mes Notes', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28 )),

        actions: [
          IconButton(icon: const Icon(Icons.search, size: 28, color: Colors.black), onPressed: () {Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );}),
          IconButton(icon: const Icon(Icons.logout_outlined, color: Colors.black), onPressed: _authService.signOut),

        ],
        
      ),
      body: Container( // On met le fond ici
        color: Colors.white,
        child: Stack(
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
                    final noteDocument = notes[index];
                    final noteData = noteDocument.data() as Map<String, dynamic>;
                    final noteId = noteDocument.id;
                    final timestamp = noteData['createdAt'] as Timestamp?;
                    String formattedDate = 'date inconnue';
                    if (timestamp != null) {
                      formattedDate = DateFormat.yMMMd('fr_FR').format(timestamp.toDate());
                    }
                    return Dismissible(
                      key: Key(noteId),
                      onDismissed: (direction) {
                        _lastDeletedNote = noteDocument;
                        _noteService.deleteNote(noteId);
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: const Text("Note supprimée"),
                          action: SnackBarAction(
                            label: 'ANNULER',
                            onPressed: () {
                              if (_lastDeletedNote != null) {
                                final data = _lastDeletedNote!.data() as Map<String, dynamic>;
                                _noteService.addNote(data['title'] ?? '', data['content'] ?? '',
                                    subject: data['subject'], createdAt: data['createdAt'], summary: data['summary']);
                              }
                            },
                          ),
                        ));
                      },
                      background: Container(
                          color: Colors.red.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerRight,
                          child: const Icon(Icons.delete_outline, color: Colors.white)),
                      direction: DismissDirection.endToStart,
                      child: NoteCard(
                        title: noteData['title'] ?? '',
                        previewContent: noteData['content'] ?? '',
                        date: formattedDate,
                        subject: noteData['subject'],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => NoteDetailScreen(noteId: noteId))),
                      ),
                    );
                  },
                );
              },
            ),

            // --- SECTION DU MENU FLOTTANT ANIMÉ ---
            AnimatedOpacity(
              opacity: _isMenuOpen ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: !_isMenuOpen,
                child: GestureDetector(
                  onTap: _toggleMenu,
                  child: Container(color: Colors.black.withOpacity(0.5)),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              bottom: _isMenuOpen ? 100 : -300,
              left: 20,
              right: 20,
              child: AnimatedOpacity(
                opacity: _isMenuOpen ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMenuItem(Icons.edit_outlined, 'Nouvelle Note', 'Ouvre l\'éditeur de texte', _navigateToAddNote),
                      const Divider(),
                      _buildMenuItem(Icons.picture_as_pdf_outlined, 'Importer un PDF', 'Extrait le texte d\'un fichier PDF', _pickAndUploadPdf),
                      const Divider(),
                      _buildMenuItem(Icons.camera_alt_outlined, 'Scanner un document', 'Ouvre l\'appareil photo pour l\'OCR', () {}),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMenu,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child));
          },
          child: Icon(
            _isMenuOpen ? Icons.close : Icons.add,
            key: ValueKey<bool>(_isMenuOpen),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
          child: BottomAppBar(
            color: const Color.fromARGB(255, 235, 233, 233).withOpacity(0.85),
            elevation: 0,
            height: 70,
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Accueil', 0, onPressed: () {  }),
                _buildNavItem(Icons.school, 'Réviser', 1, onPressed: () {  }),
                const SizedBox(width: 40),
                _buildNavItem(Icons.search, 'Rechercher', 2 , onPressed:() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  );
                }),
                _buildNavItem(Icons.person, 'Profil', 3, onPressed: () {  }),
              ],
            ),
          ),
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

  Widget _buildNavItem(IconData icon, String label, int index, {required Null Function() onPressed}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: () => _onItemTapped(index),
      tooltip: label,
    );
  }
}