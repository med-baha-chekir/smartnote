// lib/screens/main_screen.dart

import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:smartnote/screens/add_note_screen.dart';
import 'package:smartnote/screens/home_screen.dart';
import 'package:smartnote/screens/review_screen.dart';
import 'package:smartnote/screens/search_screen.dart';
import 'package:smartnote/services/note_service.dart';
import 'package:smartnote/screens/profile_screen.dart';
import 'package:smartnote/services/user_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final NoteService _noteService = NoteService();
  final UserService _userService = UserService();
  int _selectedIndex = 0;
  bool _isMenuOpen = false;

  // La liste de tous les écrans principaux pour la navigation par onglets
  final List<Widget> _screens = [
    const HomeScreen(),
    const ReviewScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];
  void initState() {
    super.initState();
    // On met à jour la série d'étude au démarrage de l'écran principal
    _userService.updateUserStudyStreak(); 
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  void _navigateToAddNote() {
    if (_isMenuOpen) _toggleMenu();
    Navigator.push(context, MaterialPageRoute(builder: (context) => AddNoteScreen()));
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
      extendBody: true,
      backgroundColor: Colors.white,
      // Le body est un Stack pour superposer les écrans principaux et le menu flottant
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),
          // --- SECTION DU MENU FLOTTANT (maintenant global) ---
          AnimatedOpacity(
            opacity: _isMenuOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_isMenuOpen,
              child: GestureDetector(onTap: _toggleMenu, child: Container(color: Colors.black.withOpacity(0.5))),
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
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMenu,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
          child: Icon( _isMenuOpen ? Icons.close : Icons.add, key: ValueKey<bool>(_isMenuOpen)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: BottomAppBar(
            color: const Color.fromARGB(255, 240, 239, 239).withOpacity(0.85),
            elevation: 0,
            height: 70,
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