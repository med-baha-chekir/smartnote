// lib/screens/quiz_screen.dart

import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  // On passe la liste des questions à cet écran
  final List<Map<String, dynamic>> questions;

  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentQuestionIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _isAnswered = false;

  void _answerQuestion(String answer) {
    setState(() {
      _isAnswered = true;
      _selectedAnswer = answer;
      if (answer == widget.questions[_currentQuestionIndex]['answer']) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _isAnswered = false;
        _selectedAnswer = null;
      });
    } else {
      // Fin du quiz
      _showResultDialog();
    }
  }
  
  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Fin du Quiz !'),
        content: Text('Votre score est de : $_score / ${widget.questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Ferme la dialog
              Navigator.pop(context); // Revient à l'écran de détail de la note
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentQuestionIndex];
    final options = List<String>.from(question['options']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz (${_currentQuestionIndex + 1}/${widget.questions.length})'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La question
            Text(
              question['question'],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // Les options de réponse
            ...options.map((option) {
              bool isSelected = _selectedAnswer == option;
              bool isCorrect = option == question['answer'];
              Color color = Colors.grey.shade200;

              if (_isAnswered) {
                if (isCorrect) {
                  color = Colors.green.shade200;
                } else if (isSelected && !isCorrect) {
                  color = Colors.red.shade200;
                }
              }

              return GestureDetector(
                onTap: _isAnswered ? null : () => _answerQuestion(option),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(option, style: const TextStyle(fontSize: 18)),
                ),
              );
            }).toList(),
            const Spacer(),
            // Bouton pour passer à la question suivante
            if (_isAnswered)
              ElevatedButton(
                onPressed: _nextQuestion,
                child: const Text('Suivant'),
              ),
          ],
        ),
      ),
    );
  }
}