import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/progress_service.dart';
import '../services/quiz_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.languageName,
    required this.levelIndex,
    this.xpPerCorrect = 10,
    this.topics = const [],
  });

  final String languageName;
  final int levelIndex; // 0-based
  final int xpPerCorrect;
  final List<String> topics;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _auth = FirebaseAuth.instance;
  final ProgressService _progress = ProgressService();
  final QuizService _quizService = QuizService();

  late final List<QuizQuestion> _questions;
  bool _loading = true;
  int _currentIndex = 0;
  int _score = 0;
  int _secondsLeft = 15;
  Timer? _timer;
  bool _answered = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final fetched = await _quizService.fetchQuestionsFromAssets(
      language: widget.languageName,
      levelIndex: widget.levelIndex,
      topics: widget.topics,
      limit: 10,
    );
    if (!mounted) return;
    setState(() {
      _questions = fetched;
      _loading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 15;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsLeft -= 1;
        if (_secondsLeft <= 0) {
          _timer?.cancel();
          _nextQuestion();
        }
      });
    });
  }

  void _answer(int index) {
    if (_answered) return;
    _answered = true;
    _selectedIndex = index;
    final correct = _questions[_currentIndex].correctIndex;
    if (index == correct) {
      _score += widget.xpPerCorrect;
    }
    // If not the last question, advance after a short delay to show colors
    final isLast = _currentIndex == _questions.length - 1;
    if (!isLast) {
      Future.delayed(const Duration(milliseconds: 800), _nextQuestion);
    }
  }

  Future<void> _nextQuestion() async {
    _answered = false;
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex += 1;
      });
      _startTimer();
      return;
    }
    _timer?.cancel();
    await _finishQuiz();
  }

  Future<void> _finishQuiz() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Award total score as XP; also mark level complete
        await _progress.completeLevel(
          userId: user.uid,
          languageName: widget.languageName,
          completedLevelIndex: widget.levelIndex,
          totalLevels: 6,
          xpPerLevel: _score, // award score
        );
      }
    } catch (e) {
      if (mounted) {
        // More detailed error logging for debugging
        print('Progress save error: $e');
        print('User: ${_auth.currentUser?.uid}');
        print('Language: ${widget.languageName}');
        print('Level: ${widget.levelIndex}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save progress: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (!mounted) return;
      // Immediately return to roadmap and refresh progress there.
      // Use a microtask to avoid popping during frame updates.
      Future.microtask(() {
        if (!mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(true);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1C2C),
        appBar: AppBar(
          title: Text(
            '${widget.languageName} • Level ${widget.levelIndex + 1}',
          ),
          backgroundColor: const Color(0xFF0B1C2C),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      );
    }
    final q = _questions[_currentIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      appBar: AppBar(
        title: Text('${widget.languageName} • Level ${widget.levelIndex + 1}'),
        backgroundColor: const Color(0xFF0B1C2C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.cyanAccent),
                const SizedBox(width: 8),
                Text(
                  '$_secondsLeft s',
                  style: GoogleFonts.robotoMono(color: Colors.white),
                ),
                const Spacer(),
                Text(
                  'Score: $_score',
                  style: GoogleFonts.robotoMono(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              q.question,
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(q.options.length, (i) {
              // Determine button color based on answer state
              Color bgColor = Colors.white12;
              if (_answered) {
                if (i == q.correctIndex) {
                  bgColor = Colors.green.withOpacity(0.25);
                } else if (_selectedIndex == i) {
                  bgColor = Colors.red.withOpacity(0.25);
                } else {
                  bgColor = Colors.white10;
                }
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton(
                  onPressed: _answered ? null : () => _answer(i),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      q.options[i],
                      style: GoogleFonts.robotoMono(fontSize: 14),
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (_currentIndex == _questions.length - 1)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    _timer?.cancel();
                    await _finishQuiz();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Submit'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
