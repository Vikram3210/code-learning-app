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

    // Check if we have questions, if not show error and return
    if (fetched.isEmpty) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No questions available for ${widget.languageName} Level ${widget.levelIndex + 1}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        // Navigate back after showing error
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
        });
      }
      return;
    }

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

    // Safety check to prevent RangeError
    if (_questions.isEmpty || _currentIndex >= _questions.length) {
      return;
    }

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

    // Safety check to prevent RangeError
    if (_questions.isEmpty) {
      _timer?.cancel();
      await _finishQuiz();
      return;
    }

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
        print(
          '🎯 Completing level: ${widget.levelIndex + 1} for ${widget.languageName}',
        );
        print('🎯 Level index (0-based): ${widget.levelIndex}');
        print('🎯 Total levels: 6');

        final result = await _progress.completeLevel(
          userId: user.uid,
          languageName: widget.languageName,
          completedLevelIndex: widget.levelIndex,
          totalLevels: 6,
          xpPerLevel: _score, // award score
        );

        print('🎯 Result from completeLevel: $result');

        // Check if course was completed and show celebration
        final courseCompleted = result['completed'] as bool? ?? false;
        print('🎯 Course completed: $courseCompleted');

        if (courseCompleted && mounted) {
          print('🎉 Showing celebration dialog!');
          _showCourseCompletionCelebration();
        } else {
          print('❌ No celebration - course not completed or not mounted');
        }
      }
    } catch (e) {
      if (mounted) {
        // More detailed error logging for debugging
        print('Progress save error: $e');
        print('User: ${_auth.currentUser?.uid}');
        print('Language: ${widget.languageName}');
        print('Level: ${widget.levelIndex}');

        // Show user-friendly error message
        String errorMessage = 'Could not save progress';
        if (e.toString().contains('cloud_firestore/unknown')) {
          errorMessage = 'Database error - please try again';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission error - please try logging in again';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timeout - please try again';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Retry saving progress
                _finishQuiz();
              },
            ),
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

  void _showCourseCompletionCelebration() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration animation
            const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 80),
            const SizedBox(height: 16),

            // Title
            Text(
              '🎉 Congratulations! 🎉',
              style: GoogleFonts.pressStart2p(
                fontSize: 16,
                color: Colors.cyanAccent,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              'You\'ve completed the entire ${widget.languageName} course!',
              style: GoogleFonts.robotoMono(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Badge info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amberAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amberAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    color: Colors.amberAccent,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Badge Earned: Completed ${widget.languageName}',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Continue button
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to roadmap
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop(true);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.robotoMono(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
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

    // Safety check to prevent RangeError
    if (_questions.isEmpty || _currentIndex >= _questions.length) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B1C2C),
        appBar: AppBar(
          title: Text(
            '${widget.languageName} • Level ${widget.levelIndex + 1}',
          ),
          backgroundColor: const Color(0xFF0B1C2C),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              SizedBox(height: 16),
              Text(
                'No questions available for this level',
                style: TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
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
