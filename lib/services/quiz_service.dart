import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class QuizQuestion {
  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.difficulty,
    required this.topics,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final int difficulty; // 1=easy,2=med,3=hard
  final List<String>
  topics; // e.g. ["Variables & Data Types", "Loops (For/While)"]
}

class QuizService {
  // Basic bank annotated with topics. You can expand this as needed.
  List<QuizQuestion> _baseBankFor(String language) {
    final common = <QuizQuestion>[
      QuizQuestion(
        question: 'What does print do?',
        options: [
          'Outputs text',
          'Reads input',
          'Compiles code',
          'Sends email',
        ],
        correctIndex: 0,
        difficulty: 1,
        topics: ['Hello World', 'Basic Syntax'],
      ),
      QuizQuestion(
        question: 'Select the keyword for a variable',
        options: ['var', 'disp', 'func', 'main'],
        correctIndex: 0,
        difficulty: 1,
        topics: ['Variables & Data Types'],
      ),
      QuizQuestion(
        question: 'A loop repeats code. True or False?',
        options: ['True', 'False', 'Depends', 'Not sure'],
        correctIndex: 0,
        difficulty: 1,
        topics: ['Loops (For/While)'],
      ),
      QuizQuestion(
        question: 'Choose a conditional keyword',
        options: ['if', 'loop', 'print', 'int'],
        correctIndex: 0,
        difficulty: 1,
        topics: ['If/Else Statements', 'Boolean Logic'],
      ),
      QuizQuestion(
        question: 'What is an array/list used for?',
        options: [
          'Store multiple values',
          'Networking',
          'Styling',
          'Compilation',
        ],
        correctIndex: 0,
        difficulty: 2,
        topics: ['Arrays/Lists'],
      ),
      QuizQuestion(
        question: 'Functions are used to...',
        options: ['Reuse code', 'Store files', 'Render CSS', 'Design UI only'],
        correctIndex: 0,
        difficulty: 2,
        topics: ['Function Definition', 'Reusable Code'],
      ),
      QuizQuestion(
        question: 'OOP stands for?',
        options: [
          'Object-Oriented Programming',
          'Only Output Print',
          'Open Office Program',
          'Other Option Please',
        ],
        correctIndex: 0,
        difficulty: 2,
        topics: ['Classes & Objects'],
      ),
      QuizQuestion(
        question: 'Which is a data type?',
        options: ['int', 'loop', 'if', 'for'],
        correctIndex: 0,
        difficulty: 1,
        topics: ['Variables & Data Types'],
      ),
      QuizQuestion(
        question: 'Errors are handled with...',
        options: ['try/except', 'style.css', 'SELECT *', 'DOCTYPE'],
        correctIndex: 0,
        difficulty: 3,
        topics: ['Error Handling'],
      ),
      QuizQuestion(
        question: 'A variable stores...',
        options: ['data', 'styles', 'tables only', 'requests only'],
        correctIndex: 0,
        difficulty: 1,
        topics: ['Variables & Data Types'],
      ),
      // Additional questions for different difficulty levels
      QuizQuestion(
        question: 'What is inheritance in programming?',
        options: [
          'A way to reuse code from parent classes',
          'A type of loop',
          'A data structure',
          'A debugging tool',
        ],
        correctIndex: 0,
        difficulty: 3,
        topics: ['Classes & Objects', 'Inheritance'],
      ),
      QuizQuestion(
        question: 'What is polymorphism?',
        options: [
          'One interface, multiple implementations',
          'A type of variable',
          'A loop structure',
          'A file format',
        ],
        correctIndex: 0,
        difficulty: 3,
        topics: ['Classes & Objects', 'Polymorphism'],
      ),
      QuizQuestion(
        question: 'What is encapsulation?',
        options: [
          'Hiding internal implementation details',
          'A type of array',
          'A function parameter',
          'A comment style',
        ],
        correctIndex: 0,
        difficulty: 3,
        topics: ['Classes & Objects', 'Encapsulation'],
      ),
      QuizQuestion(
        question: 'What is a constructor?',
        options: [
          'A special method that initializes objects',
          'A type of loop',
          'A variable declaration',
          'A comment block',
        ],
        correctIndex: 0,
        difficulty: 2,
        topics: ['Classes & Objects'],
      ),
      QuizQuestion(
        question: 'What is method overloading?',
        options: [
          'Multiple methods with same name but different parameters',
          'A type of inheritance',
          'A loop structure',
          'A data type',
        ],
        correctIndex: 0,
        difficulty: 3,
        topics: ['Classes & Objects', 'Method Overloading'],
      ),
    ];

    switch (language) {
      case 'HTML':
        return common
            .map(
              (q) => QuizQuestion(
                question: q.question
                    .replaceAll('variable', 'element')
                    .replaceAll('Functions', 'Tags')
                    .replaceAll('array/list', 'list of elements'),
                options: q.options,
                correctIndex: q.correctIndex,
                difficulty: q.difficulty,
                topics: q.topics,
              ),
            )
            .toList();
      case 'CSS':
        return common
            .map(
              (q) => QuizQuestion(
                question: q.question
                    .replaceAll('Functions', 'Selectors')
                    .replaceAll('variable', 'rule'),
                options: q.options,
                correctIndex: q.correctIndex,
                difficulty: q.difficulty,
                topics: q.topics,
              ),
            )
            .toList();
      default:
        return common;
    }
  }

  /// Returns counts of questions per language per difficulty from assets.
  /// Shape: { language: { difficulty: count } }
  Future<Map<String, Map<int, int>>> computeQuestionCountsFromAssets() async {
    final Map<String, Map<int, int>> counts = <String, Map<int, int>>{};
    try {
      final jsonStr = await rootBundle.loadString('assets/questions.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> raw = (data['questions'] ?? []) as List<dynamic>;

      for (final dynamic entry in raw) {
        final m = entry as Map<String, dynamic>;
        final String language = (m['language'] ?? '').toString();
        if (language.isEmpty) continue;

        counts.putIfAbsent(language, () => <int, int>{});

        // Case 1: flat question entry at root
        if (m.containsKey('question')) {
          final int diff = (m['difficulty'] ?? 0) is int
              ? (m['difficulty'] as int)
              : int.tryParse((m['difficulty'] ?? '0').toString()) ?? 0;
          if (diff > 0) {
            counts[language]![diff] = (counts[language]![diff] ?? 0) + 1;
          }
          continue;
        }

        // Case 2: nested language block containing levels with questions
        if (m.containsKey('levels')) {
          final List levels = (m['levels'] as List?) ?? const [];
          for (final level in levels) {
            final levelMap = level as Map<String, dynamic>;
            final List questions = (levelMap['questions'] as List?) ?? const [];
            for (final q in questions) {
              final qm = q as Map<String, dynamic>;
              final int diff = (qm['difficulty'] ?? 0) is int
                  ? (qm['difficulty'] as int)
                  : int.tryParse((qm['difficulty'] ?? '0').toString()) ?? 0;
              if (diff > 0) {
                counts[language]![diff] = (counts[language]![diff] ?? 0) + 1;
              }
            }
          }
        }
      }
    } catch (_) {
      // ignore and return whatever accumulated (possibly empty)
    }
    return counts;
  }

  List<QuizQuestion> getQuestions({
    required String language,
    required int levelIndex,
    List<String>? topics,
    int limit = 10,
  }) {
    final bank = _baseBankFor(language);
    final levelDifficulty =
        levelIndex + 1; // Level 1 = difficulty 1, Level 2 = difficulty 2, etc.

    // Filter by exact difficulty match and by topics if provided
    final filtered = bank.where((q) {
      final difficultyMatch = q.difficulty == levelDifficulty;
      final topicMatch = (topics == null || topics.isEmpty)
          ? true
          : q.topics.any((t) => topics.contains(t));
      return difficultyMatch && topicMatch;
    }).toList();

    // Shuffle deterministically per level to vary across levels but remain stable within a session
    filtered.shuffle();

    if (filtered.length > limit) {
      return filtered.sublist(0, limit);
    }
    return filtered;
  }

  Future<List<QuizQuestion>> fetchQuestionsFromDataset({
    required String language,
    required int levelIndex,
    List<String>? topics,
    int limit = 10,
    FirebaseFirestore? firestore,
  }) async {
    final db = firestore ?? FirebaseFirestore.instance;
    final levelDifficulty =
        levelIndex + 1; // Level 1 = difficulty 1, Level 2 = difficulty 2, etc.

    // Base query by language and difficulty
    Query<Map<String, dynamic>> query = db
        .collection('questions')
        .where('language', isEqualTo: language)
        .where('difficulty', isEqualTo: levelDifficulty);

    // Optional topic filter: if topics provided, fetch any that match
    if (topics != null && topics.isNotEmpty) {
      // Assumes each question document has an array field 'topics'
      query = query.where('topics', arrayContainsAny: topics.take(10).toList());
    }

    query = query.limit(limit);

    final snap = await query.get();
    final results = snap.docs.map((doc) {
      final data = doc.data();
      return QuizQuestion(
        question: (data['question'] ?? '') as String,
        options: List<String>.from((data['options'] ?? const []) as List),
        correctIndex: (data['correctIndex'] ?? 0) as int,
        difficulty: (data['difficulty'] ?? levelDifficulty) as int,
        topics: List<String>.from((data['topics'] ?? const []) as List),
      );
    }).toList();

    // If dataset is empty, fall back to local bank
    if (results.isEmpty) {
      return getQuestions(
        language: language,
        levelIndex: levelIndex,
        topics: topics,
        limit: limit,
      );
    }

    return results;
  }

  Future<List<QuizQuestion>> fetchQuestionsFromAssets({
    required String language,
    required int levelIndex,
    List<String>? topics,
    int limit = 10,
  }) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/questions.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> raw = (data['questions'] ?? []) as List<dynamic>;
      final levelDifficulty =
          levelIndex +
          1; // Level 1 = difficulty 1, Level 2 = difficulty 2, etc.
      // Build questions filtered by language, supporting both flat entries and nested (levels -> questions)
      final List<QuizQuestion> byLanguage = [];
      for (final dynamic entry in raw) {
        final Map<String, dynamic> m = entry as Map<String, dynamic>;
        if ((m['language'] ?? '') != language) continue;

        // Case 1: flat question entry at root
        if (m.containsKey('question')) {
          byLanguage.add(
            QuizQuestion(
              question: (m['question'] ?? '') as String,
              options: List<String>.from((m['options'] ?? const []) as List),
              correctIndex: (m['correctIndex'] ?? 0) as int,
              difficulty: (m['difficulty'] ?? levelDifficulty) as int,
              topics: List<String>.from((m['topics'] ?? const []) as List),
            ),
          );
          continue;
        }

        // Case 2: nested language block containing levels with questions
        if (m.containsKey('levels')) {
          final List levels = (m['levels'] as List?) ?? const [];
          for (final level in levels) {
            final levelMap = level as Map<String, dynamic>;
            final List questions = (levelMap['questions'] as List?) ?? const [];
            for (final q in questions) {
              final qm = q as Map<String, dynamic>;
              byLanguage.add(
                QuizQuestion(
                  question: (qm['question'] ?? '') as String,
                  options: List<String>.from(
                    (qm['options'] ?? const []) as List,
                  ),
                  correctIndex: (qm['correctIndex'] ?? 0) as int,
                  difficulty: (qm['difficulty'] ?? levelDifficulty) as int,
                  topics: List<String>.from((qm['topics'] ?? const []) as List),
                ),
              );
            }
          }
        }
      }

      // Apply difficulty and topic filters
      List<QuizQuestion> finalFiltered = byLanguage.where((q) {
        final difficultyMatch = q.difficulty == levelDifficulty;
        final topicMatch = (topics == null || topics.isEmpty)
            ? true
            : q.topics.any((t) => topics.contains(t));
        return difficultyMatch && topicMatch;
      }).toList();

      finalFiltered.shuffle();
      // If we have fewer than requested, backfill by relaxing filters
      if (finalFiltered.length < limit) {
        // 1) Relax topic filter but keep difficulty
        final byDifficultyOnly = byLanguage.where((q) {
          return q.difficulty == levelDifficulty;
        }).toList();
        byDifficultyOnly.shuffle();
        for (final q in byDifficultyOnly) {
          if (finalFiltered.length >= limit) break;
          if (!finalFiltered.contains(q)) finalFiltered.add(q);
        }

        // 2) If still short, pull from local base bank at difficulty
        if (finalFiltered.length < limit) {
          final fallback = getQuestions(
            language: language,
            levelIndex: levelIndex,
            topics: const [],
            limit: limit,
          );
          for (final q in fallback) {
            if (finalFiltered.length >= limit) break;
            // Only include those matching level difficulty strictly
            if (q.difficulty == levelDifficulty && !finalFiltered.contains(q)) {
              finalFiltered.add(q);
            }
          }
        }
      }

      if (finalFiltered.length > limit) {
        finalFiltered = finalFiltered.sublist(0, limit);
      }
      if (finalFiltered.isNotEmpty) return finalFiltered;

      // Fallback to local base bank if none
      return getQuestions(
        language: language,
        levelIndex: levelIndex,
        topics: topics,
        limit: limit,
      );
    } catch (_) {
      // If assets missing or JSON invalid, fallback
      return getQuestions(
        language: language,
        levelIndex: levelIndex,
        topics: topics,
        limit: limit,
      );
    }
  }

  Future<List<String>> fetchLevelTopicsFromAssets({
    required String language,
    required int levelIndex,
    int totalLevels = 6,
  }) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/questions.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> raw = (data['questions'] ?? []) as List<dynamic>;

      // 1) If language block uses nested levels, return its explicit topics
      for (final dynamic entry in raw) {
        final m = entry as Map<String, dynamic>;
        if ((m['language'] ?? '') != language) continue;
        if (m.containsKey('levels')) {
          final levels = (m['levels'] as List?) ?? const [];
          final targetLevelNumber = levelIndex + 1;
          for (final level in levels) {
            final lm = level as Map<String, dynamic>;
            final num = (lm['level'] ?? -1) as int;
            if (num == targetLevelNumber) {
              final topics = List<String>.from(
                (lm['topics'] ?? const []) as List,
              );
              if (topics.isNotEmpty) return topics;
            }
          }
        }
      }

      // 2) Otherwise derive topics from questions by exact difficulty match
      final levelDifficulty =
          levelIndex +
          1; // Level 1 = difficulty 1, Level 2 = difficulty 2, etc.
      final Set<String> topicSet = <String>{};
      for (final dynamic entry in raw) {
        final m = entry as Map<String, dynamic>;
        if ((m['language'] ?? '') != language) continue;
        if (m.containsKey('question')) {
          final diff = (m['difficulty'] ?? 0) as int;
          if (diff == levelDifficulty) {
            final ts = (m['topics'] as List?) ?? const [];
            for (final t in ts) {
              if (t is String) topicSet.add(t);
            }
          }
        }
      }
      return topicSet.toList();
    } catch (_) {
      return <String>[];
    }
  }

  Future<Map<String, dynamic>?> fetchLevelInfoFromAssets({
    required String language,
    required int levelIndex,
  }) async {
    try {
      final jsonStr = await rootBundle.loadString('assets/questions.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final List<dynamic> raw = (data['questions'] ?? []) as List<dynamic>;
      final int target = levelIndex + 1;
      for (final dynamic entry in raw) {
        final m = entry as Map<String, dynamic>;
        if ((m['language'] ?? '') != language) continue;
        if (m.containsKey('levels')) {
          final levels = (m['levels'] as List?) ?? const [];
          for (final level in levels) {
            final lm = level as Map<String, dynamic>;
            if ((lm['level'] ?? -1) == target) {
              return {
                'name': lm['name'],
                'topics': lm['topics'],
                'duration': lm['duration'],
                'difficulty': lm['difficulty'],
                'status': lm['status'],
              };
            }
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
