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
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:smartnote/utils/snackbar_helper.dart';

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

      final snackBar = SnackBar(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 16),
          const Text('Import et analyse du PDF en cours...'),
        ],
      ),
      duration: const Duration(minutes: 5), // Durée très longue pour qu'elle reste visible
    );

    // On garde une référence à notre SnackBar pour pouvoir la cacher plus tard
    final snackBarController = ScaffoldMessenger.of(context).showSnackBar(snackBar);

    try {
      // 2. On lance l'upload et on attend que ce soit fini
      await _noteService.uploadPdf(file);

      // 3. Si l'upload réussit, on cache la SnackBar de chargement...
      snackBarController.close();
      
      // ...et on en affiche une nouvelle pour confirmer le succès.
      if (mounted) {
        SnackBarHelper.show(context, 'PDF importé ! La nouvelle note apparaîtra bientôt.');
      }
    } catch (e) {
      // 4. Si une erreur se produit...
      // On cache la SnackBar de chargement...
      snackBarController.close();

      // ...et on affiche un message d'erreur.
      if (mounted) {
        SnackBarHelper.showError(context, 'L\'import du PDF a échoué.');
      }
    }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import du PDF en cours...')),
      );
      await _noteService.uploadPdf(file);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF importé ! La nouvelle note apparaîtra bientôt.')),
      );
    }
  }
  Future<void> _scanDocument(ImageSource source) async {
  // On ferme le menu avant de faire quoi que ce soit
  if (_isMenuOpen) _toggleMenu();

  final ImagePicker _picker = ImagePicker();
  
  // 1. L'utilisateur choisit une image
  final XFile? imageFile = await _picker.pickImage(source: source);

  if (imageFile == null) {
    // L'utilisateur a annulé
    return;
  }

  // On peut afficher un indicateur de chargement
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Analyse de l\'image en cours...')),
  );

  try {
    // 2. On prépare l'image et l'outil de reconnaissance
    final inputImage = InputImage.fromFilePath(imageFile.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    // 3. On traite l'image pour extraire le texte
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    
    // On ferme l'outil après usage
    await textRecognizer.close();
    
    // On récupère le texte brut
    final String extractedText = recognizedText.text;

     // --- AJOUTEZ CES LIGNES DE DÉBOGAGE ---
  print('--- OCR RESULT ---');
  print('Le texte extrait contient ${extractedText.length} caractères.');
  print('Texte extrait : "$extractedText"');
  print('--- END OCR RESULT ---');
  // --- FIN DES LIGNES DE DÉBOGAGE ---

    // 4. On navigue vers l'écran d'ajout de note avec le texte pré-rempli
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddNoteScreen(
            // On passe le texte extrait au champ de contenu
            initialContent: extractedText,
          ),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'analyse de l\'image : $e')),
      );
    }
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
                    _buildMenuItem(
  Icons.camera_alt_outlined,
  'Scanner un document',
  'Prendre une photo ou choisir une image',
  () {
    // Affiche une boîte de dialogue pour le choix de la source
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Appareil photo'),
            onTap: () {
              Navigator.of(context).pop();
              _scanDocument(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Galerie'),
            onTap: () {
              Navigator.of(context).pop();
              _scanDocument(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  },
),
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