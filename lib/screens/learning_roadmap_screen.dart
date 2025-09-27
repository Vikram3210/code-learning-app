import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/progress_service.dart';
import '../services/quiz_service.dart';
import 'quiz_screen.dart';

class LearningRoadmapScreen extends StatefulWidget {
  final String languageName;
  final String languageIcon;
  final Color languageColor;

  const LearningRoadmapScreen({
    super.key,
    required this.languageName,
    required this.languageIcon,
    required this.languageColor,
  });

  @override
  State<LearningRoadmapScreen> createState() => _LearningRoadmapScreenState();
}

class _LearningRoadmapScreenState extends State<LearningRoadmapScreen> {
  final _auth = FirebaseAuth.instance;
  final ProgressService _progressService = ProgressService();
  final QuizService _quizService = QuizService();

  bool _isLoading = false;
  int _completedLevels = 0;
  int _languageXp = 0;
  bool _courseCompleted = false;

  // Make levels mutable so we can replace topics per language
  late List<Map<String, dynamic>> _learningLevels;
  List<Map<String, dynamic>> _defaultLevels() => [
    {
      'title': 'Level 1: Basics',
      'subtitle': 'Getting Started',
      'description': 'Learn the fundamentals and syntax',
      'topics': [
        'Variables & Data Types',
        'Basic Syntax',
        'Hello World',
        'Comments',
      ],
      'duration': '2-3 weeks',
      'difficulty': 'Beginner',
      'completed': false,
      'locked': false,
    },
    {
      'title': 'Level 2: Control Flow',
      'subtitle': 'Making Decisions',
      'description': 'Conditionals and loops',
      'topics': [
        'If/Else Statements',
        'Loops (For/While)',
        'Switch Cases',
        'Boolean Logic',
      ],
      'duration': '2-3 weeks',
      'difficulty': 'Beginner',
      'completed': false,
      'locked': false,
    },
    {
      'title': 'Level 3: Functions',
      'subtitle': 'Reusable Code',
      'description': 'Creating and using functions',
      'topics': [
        'Function Definition',
        'Parameters & Arguments',
        'Return Values',
        'Scope',
      ],
      'duration': '2-3 weeks',
      'difficulty': 'Beginner',
      'completed': false,
      'locked': false,
    },
    {
      'title': 'Level 4: Data Structures',
      'subtitle': 'Organizing Data',
      'description': 'Arrays, lists, and collections',
      'topics': ['Arrays/Lists', 'Dictionaries/Maps', 'Sets', 'Iteration'],
      'duration': '3-4 weeks',
      'difficulty': 'Intermediate',
      'completed': false,
      'locked': true,
    },
    {
      'title': 'Level 5: Object-Oriented Programming',
      'subtitle': 'Classes & Objects',
      'description': 'OOP concepts and design patterns',
      'topics': [
        'Classes & Objects',
        'Inheritance',
        'Polymorphism',
        'Encapsulation',
      ],
      'duration': '4-5 weeks',
      'difficulty': 'Intermediate',
      'completed': false,
      'locked': true,
    },
    {
      'title': 'Level 6: Advanced Concepts',
      'subtitle': 'Expert Level',
      'description': 'Advanced programming techniques',
      'topics': ['Error Handling', 'File I/O', 'Modules/Packages', 'Testing'],
      'duration': '4-6 weeks',
      'difficulty': 'Advanced',
      'completed': false,
      'locked': true,
    },
  ];

  int get totalLevels => _learningLevels.length;

  @override
  void initState() {
    super.initState();
    _learningLevels = _defaultLevels();
    _loadProgress();
    _loadDynamicTopics();
  }

  Future<void> _loadDynamicTopics() async {
    // Replace default topics with language-specific topics derived from assets
    // and ensure topics do not repeat across levels for the same language
    final Set<String> seenTopics = <String>{};
    for (int i = 0; i < _learningLevels.length; i++) {
      // Load metadata (name/topics/duration/difficulty) per language level if available
      final info = await _quizService.fetchLevelInfoFromAssets(
        language: widget.languageName,
        levelIndex: i,
      );
      if (info != null) {
        if (info['name'] is String && (info['name'] as String).isNotEmpty) {
          _learningLevels[i]['title'] =
              'Level ${i + 1}: ${info['name'] as String}';
        } else {
          final fb = _fallbackLevelMeta(widget.languageName, i);
          _learningLevels[i]['title'] = 'Level ${i + 1}: ${fb['name']}';
        }
        if (info['subtitle'] is String &&
            (info['subtitle'] as String).isNotEmpty) {
          _learningLevels[i]['subtitle'] = info['subtitle'] as String;
        } else {
          final fb = _fallbackLevelMeta(widget.languageName, i);
          _learningLevels[i]['subtitle'] = fb['subtitle']!;
        }
        if (info['description'] is String &&
            (info['description'] as String).isNotEmpty) {
          _learningLevels[i]['description'] = info['description'] as String;
        } else {
          final fb = _fallbackLevelMeta(widget.languageName, i);
          _learningLevels[i]['description'] = fb['description']!;
        }
        if (info['duration'] is String) {
          _learningLevels[i]['duration'] = info['duration'] as String;
        }
        if (info['difficulty'] is String) {
          _learningLevels[i]['difficulty'] = info['difficulty'] as String;
        }
      } else {
        final fb = _fallbackLevelMeta(widget.languageName, i);
        _learningLevels[i]['title'] = 'Level ${i + 1}: ${fb['name']}';
        _learningLevels[i]['subtitle'] = fb['subtitle']!;
        _learningLevels[i]['description'] = fb['description']!;
      }

      final topics = await _quizService.fetchLevelTopicsFromAssets(
        language: widget.languageName,
        levelIndex: i,
        totalLevels: totalLevels,
      );
      // Derive topics from title/subtitle/description if available
      final inferred = _inferTopicsFromMeta(
        language: widget.languageName,
        title: (_learningLevels[i]['title'] as String?) ?? '',
        subtitle: (_learningLevels[i]['subtitle'] as String?) ?? '',
        description: (_learningLevels[i]['description'] as String?) ?? '',
      );

      final sourceTopics = inferred.isNotEmpty ? inferred : topics;
      if (sourceTopics.isNotEmpty) {
        // Remove topics already used in earlier levels
        final uniqueTopics = sourceTopics
            .where((t) => !seenTopics.contains(t))
            .toList();
        // Prefer unique subset; if empty, keep original to avoid blank chips
        final applied = uniqueTopics.isNotEmpty ? uniqueTopics : sourceTopics;
        // Optionally cap to 4 topics for UI neatness
        final capped = applied.length > 4 ? applied.sublist(0, 4) : applied;
        _learningLevels[i]['topics'] = capped;
        // Mark these as seen
        for (final t in capped) {
          seenTopics.add(t);
        }
      }
    }
    if (mounted) setState(() {});
  }

  List<String> _inferTopicsFromMeta({
    required String language,
    required String title,
    required String subtitle,
    required String description,
  }) {
    final text =
        '${title.toLowerCase()} ${subtitle.toLowerCase()} ${description.toLowerCase()}';
    final List<String> out = [];

    void addAll(List<String> ts) {
      for (final t in ts) {
        if (!out.contains(t)) out.add(t);
      }
    }

    switch (language) {
      case 'HTML':
        if (text.contains('basic') ||
            text.contains('element') ||
            text.contains('structure')) {
          addAll([
            'Elements & Structure',
            'Basic Tags (html, head, body)',
            'Attributes',
            'Comments',
          ]);
        }
        if (text.contains('content') ||
            text.contains('media') ||
            text.contains('image') ||
            text.contains('table')) {
          addAll([
            'Text & Headings',
            'Links & Images',
            'Lists & Tables',
            'Media (audio, video)',
          ]);
        }
        if (text.contains('semantic') ||
            text.contains('a11y') ||
            text.contains('accessib') ||
            text.contains('metadata')) {
          addAll([
            'Semantic Elements (header, main, article, footer)',
            'Sections & Headings',
            'Accessibility Basics',
            'Metadata & Head',
          ]);
        }
        if (text.contains('form') ||
            text.contains('input') ||
            text.contains('validate')) {
          addAll([
            'Form Structure',
            'Input Types & Labels',
            'Validation',
            'iframes & Embeds',
          ]);
        }
        if (text.contains('seo') ||
            text.contains('aria') ||
            text.contains('microdata') ||
            text.contains('international')) {
          addAll([
            'SEO Essentials',
            'Accessibility (ARIA)',
            'Microdata / Structured Data',
            'Internationalization',
          ]);
        }
        if (text.contains('api') ||
            text.contains('performance') ||
            text.contains('component') ||
            text.contains('canvas')) {
          addAll([
            'Performance & Loading',
            'HTML5 APIs (Canvas, Media)',
            'Web Components Basics',
            'Progressive Enhancement',
          ]);
        }
        break;
      case 'CSS':
        if (text.contains('basic') ||
            text.contains('selector') ||
            text.contains('unit')) {
          addAll([
            'CSS Syntax & Selectors',
            'Applying Styles',
            'Colors & Units',
            'Comments',
          ]);
        }
        if (text.contains('layout') ||
            text.contains('box model') ||
            text.contains('position')) {
          addAll([
            'Box Model',
            'Display & Positioning',
            'Flexbox Basics',
            'Responsive Units',
          ]);
        }
        if (text.contains('typograph') ||
            text.contains('font') ||
            text.contains('image') ||
            text.contains('icon') ||
            text.contains('animation')) {
          addAll([
            'Fonts & Text',
            'Images & Backgrounds',
            'Icons',
            'Basic Animations',
          ]);
        }
        if (text.contains('grid') ||
            text.contains('flexbox') ||
            text.contains('responsive') ||
            text.contains('media quer')) {
          addAll([
            'Flexbox Advanced',
            'CSS Grid',
            'Media Queries',
            'Responsive Patterns',
          ]);
        }
        if (text.contains('bem') ||
            text.contains('specific') ||
            text.contains('variable')) {
          addAll([
            'Variables & Custom Properties',
            'BEM & Organization',
            'Cascade & Specificity',
            'Accessibility Styling',
          ]);
        }
        if (text.contains('transition') ||
            text.contains('keyframe') ||
            text.contains('transform') ||
            text.contains('container quer') ||
            text.contains('performance')) {
          addAll([
            'Transitions & Keyframes',
            'Transforms',
            'Modern Features (container queries)',
            'Performance',
          ]);
        }
        break;
      case 'JavaScript':
        if (text.contains('basic') ||
            text.contains('variable') ||
            text.contains('type')) {
          addAll([
            'Variables (let/const)',
            'Data Types',
            'Operators',
            'Console & Comments',
          ]);
        }
        if (text.contains('control flow') ||
            text.contains('if') ||
            text.contains('loop') ||
            text.contains('switch')) {
          addAll(['If/Else', 'Loops', 'Switch', 'Truthiness']);
        }
        if (text.contains('function') ||
            text.contains('arrow') ||
            text.contains('scope') ||
            text.contains('hoist')) {
          addAll([
            'Function Declarations/Expressions',
            'Arrow Functions',
            'Scope & Hoisting',
            'Parameters & Return',
          ]);
        }
        if (text.contains('data structure') ||
            text.contains('array') ||
            text.contains('object') ||
            text.contains('map') ||
            text.contains('set')) {
          addAll([
            'Arrays & Methods',
            'Objects & Destructuring',
            'Maps/Sets',
            'Iteration',
          ]);
        }
        if (text.contains('async') ||
            text.contains('promise') ||
            text.contains('fetch')) {
          addAll([
            'Promises',
            'async/await',
            'Fetch/API Calls',
            'Error Handling',
          ]);
        }
        if (text.contains('dom') ||
            text.contains('module') ||
            text.contains('event') ||
            text.contains('browser')) {
          addAll(['Modules', 'DOM Basics', 'Events', 'Performance']);
        }
        break;
      case 'Java':
        if (text.contains('start') ||
            text.contains('basic') ||
            text.contains('syntax')) {
          addAll([
            'Hello World',
            'Basic Syntax',
            'Variables & Data Types',
            'Comments',
          ]);
        }
        if (text.contains('control') ||
            text.contains('flow') ||
            text.contains('loop') ||
            text.contains('switch')) {
          addAll([
            'If/Else Statements',
            'Loops',
            'Switch Cases',
            'Boolean Logic',
          ]);
        }
        if (text.contains('method') ||
            text.contains('function') ||
            text.contains('return') ||
            text.contains('scope')) {
          addAll([
            'Function Definition (Methods)',
            'Return Values',
            'Scope',
            'Parameters & Arguments',
          ]);
        }
        if (text.contains('array') ||
            text.contains('collection') ||
            text.contains('iterat')) {
          addAll(['Arrays/Lists', 'Dictionaries/Maps', 'Sets', 'Iteration']);
        }
        if (text.contains('oop') ||
            text.contains('class') ||
            text.contains('inherit') ||
            text.contains('polymorph') ||
            text.contains('encaps')) {
          addAll([
            'Classes & Objects',
            'Inheritance',
            'Polymorphism',
            'Encapsulation',
          ]);
        }
        if (text.contains('advanced') ||
            text.contains('exception') ||
            text.contains('file') ||
            text.contains('package')) {
          addAll(['Error Handling', 'File I/O', 'Modules/Packages', 'Testing']);
        }
        break;
      case 'Python':
        if (text.contains('basic') ||
            text.contains('syntax') ||
            text.contains('variable')) {
          addAll([
            'Variables & Data Types',
            'Basic Syntax',
            'Hello World',
            'Comments',
          ]);
        }
        if (text.contains('control') ||
            text.contains('flow') ||
            text.contains('loop') ||
            text.contains('boolean')) {
          addAll([
            'If/Else Statements',
            'Loops (For/While)',
            'Switch Cases',
            'Boolean Logic',
          ]);
        }
        if (text.contains('function') ||
            text.contains('scope') ||
            text.contains('return')) {
          addAll([
            'Function Definition',
            'Parameters & Arguments',
            'Return Values',
            'Scope',
          ]);
        }
        if (text.contains('data structure') ||
            text.contains('list') ||
            text.contains('dict') ||
            text.contains('set')) {
          addAll(['Arrays/Lists', 'Dictionaries/Maps', 'Sets', 'Iteration']);
        }
        if (text.contains('object') ||
            text.contains('oop') ||
            text.contains('class')) {
          addAll([
            'Classes & Objects',
            'Inheritance',
            'Polymorphism',
            'Encapsulation',
          ]);
        }
        if (text.contains('advanced') ||
            text.contains('error') ||
            text.contains('file') ||
            text.contains('module') ||
            text.contains('test')) {
          addAll(['Error Handling', 'File I/O', 'Modules/Packages', 'Testing']);
        }
        break;
      case 'C':
        if (text.contains('basic') ||
            text.contains('syntax') ||
            text.contains('variable')) {
          addAll([
            'Hello World',
            'Basic Syntax',
            'Variables & Data Types',
            'Comments',
          ]);
        }
        if (text.contains('control') ||
            text.contains('flow') ||
            text.contains('operator') ||
            text.contains('loop')) {
          addAll(['If/Else', 'Loops', 'Switch', 'Operators']);
        }
        if (text.contains('pointer') ||
            text.contains('function') ||
            text.contains('scope')) {
          addAll([
            'Function Declarations',
            'Parameters & Return',
            'Pointers Basics',
            'Scope',
          ]);
        }
        if (text.contains('data structure') ||
            text.contains('array') ||
            text.contains('struct') ||
            text.contains('enum')) {
          addAll(['Arrays & Strings', 'Structs', 'Enums', 'Iteration']);
        }
        if (text.contains('memory') ||
            text.contains('file') ||
            text.contains('malloc') ||
            text.contains('free')) {
          addAll([
            'Dynamic Memory (malloc/free)',
            'Pointers Advanced',
            'File I/O',
            'Error Handling',
          ]);
        }
        if (text.contains('advanced') ||
            text.contains('preprocessor') ||
            text.contains('macro') ||
            text.contains('performance')) {
          addAll([
            'Preprocessor & Macros',
            'Make & Build',
            'Performance',
            'Portability',
          ]);
        }
        break;
      default:
        break;
    }
    return out;
  }

  Future<void> _loadProgress() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      final snap = await _progressService.getLanguageProgress(
        user.uid,
        widget.languageName,
      );
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        _completedLevels = (data['completedLevels'] ?? 0) as int;
        _languageXp = (data['xp'] ?? 0) as int;
        _courseCompleted = (data['completed'] ?? false) as bool;
      }
    } catch (_) {
      // Show UI even if progress load fails
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _completeLevel(int index) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (index != _completedLevels) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete previous levels first.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final updated = await _progressService.completeLevel(
      userId: user.uid,
      languageName: widget.languageName,
      completedLevelIndex: index,
      totalLevels: totalLevels,
    );
    _completedLevels = (updated['completedLevels'] ?? _completedLevels) as int;
    _languageXp = (updated['xp'] ?? _languageXp) as int;
    _courseCompleted = (updated['completed'] ?? _courseCompleted) as bool;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.map, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text(
              '${widget.languageName} Path',
              style: GoogleFonts.pressStart2p(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B1C2C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.languageColor.withOpacity(0.8),
                          widget.languageColor.withOpacity(0.4),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        AnimatedTextKit(
                          animatedTexts: [
                            TyperAnimatedText(
                              '🎯 Your Learning Journey',
                              textStyle: GoogleFonts.pressStart2p(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              speed: const Duration(milliseconds: 100),
                            ),
                          ],
                          totalRepeatCount: 1,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Master ${widget.languageName} step by step',
                          style: GoogleFonts.robotoMono(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Progress Overview
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: widget.languageColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall Progress',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${((_completedLevels / totalLevels) * 100).toStringAsFixed(0)}% Complete • $_completedLevels/$totalLevels Levels • XP: $_languageXp',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.languageColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _courseCompleted
                                    ? 'Completed'
                                    : (_completedLevels < 2
                                          ? 'Beginner'
                                          : (_completedLevels < 4
                                                ? 'Intermediate'
                                                : 'Advanced')),
                                style: GoogleFonts.robotoMono(
                                  fontSize: 10,
                                  color: widget.languageColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Animated progress bar
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final fraction = (totalLevels == 0)
                                ? 0.0
                                : (_completedLevels / totalLevels).clamp(
                                    0.0,
                                    1.0,
                                  );
                            return Stack(
                              children: [
                                Container(
                                  width: width,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeInOut,
                                  width: width * fraction,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: widget.languageColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Learning Levels
                  Text(
                    'Learning Path',
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _learningLevels.length,
                    itemBuilder: (context, index) {
                      final level = Map<String, dynamic>.from(
                        _learningLevels[index],
                      );
                      final isLocked = index > _completedLevels;
                      final isCompleted = index < _completedLevels;
                      level['locked'] = isLocked;
                      level['completed'] = isCompleted;
                      return _buildLevelCard(context, level, index);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    Map<String, dynamic> level,
    int index,
  ) {
    final isLocked = level['locked'] as bool;
    final isCompleted = level['completed'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isLocked
                  ? Colors.white.withOpacity(0.03)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isLocked
                    ? Colors.white.withOpacity(0.1)
                    : widget.languageColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey.withOpacity(0.3)
                            : widget.languageColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: isLocked
                            ? const Icon(
                                Icons.lock,
                                color: Colors.grey,
                                size: 20,
                              )
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted
                                      ? Colors.green
                                      : widget.languageColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level['title'],
                            style: GoogleFonts.robotoMono(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isLocked ? Colors.grey : Colors.white,
                            ),
                          ),
                          Text(
                            level['subtitle'],
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              color: isLocked ? Colors.grey : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Place Completed chip below title/subtitle to avoid overlap
                  ],
                ),
                const SizedBox(height: 12),
                if (isCompleted)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Completed',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                Text(
                  level['description'],
                  style: GoogleFonts.robotoMono(
                    fontSize: 14,
                    color: isLocked ? Colors.grey : Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),

                // Topics
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: (level['topics'] as List<String>).map((topic) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.grey.withOpacity(0.2)
                            : widget.languageColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        topic,
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          color: isLocked ? Colors.grey : widget.languageColor,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),

                // Duration and Difficulty
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isLocked ? Colors.grey : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      level['duration'],
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: isLocked ? Colors.grey : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.signal_cellular_alt,
                      size: 16,
                      color: isLocked ? Colors.grey : Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      level['difficulty'],
                      style: GoogleFonts.robotoMono(
                        fontSize: 12,
                        color: isLocked ? Colors.grey : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Button and card tap
          if (!isLocked)
            Positioned(
              right: 12,
              top: 12,
              child: GestureDetector(
                onTap: () {
                  _showLevelDetails(context, level, index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: widget.languageColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted ? 'Review' : 'Start',
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLevelDetails(
    BuildContext context,
    Map<String, dynamic> level,
    int index,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A38),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          level['title'],
          style: GoogleFonts.robotoMono(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              level['description'],
              style: GoogleFonts.robotoMono(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Text(
              'Topics to cover:',
              style: GoogleFonts.robotoMono(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...(level['topics'] as List<String>).map(
              (topic) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: widget.languageColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      topic,
                      style: GoogleFonts.robotoMono(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text(
              "Close",
              style: TextStyle(color: Colors.cyanAccent),
            ),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    languageName: widget.languageName,
                    levelIndex: index,
                    topics: List<String>.from(level['topics'] as List<String>),
                  ),
                ),
              );
              if (result == true) {
                await _loadProgress();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.languageColor,
              foregroundColor: Colors.white,
            ),
            child: Text(level['completed'] ? 'Review' : 'Start Quiz'),
          ),
        ],
      ),
    );
  }

  Map<String, String> _fallbackLevelMeta(String language, int levelIndex) {
    final int i = levelIndex; // 0-based
    switch (language) {
      case 'HTML':
        const names = [
          'Basics',
          'Content & Media',
          'Semantics',
          'Forms',
          'Best Practices',
          'Advanced HTML5',
        ];
        const subs = [
          'Elements, structure, attributes',
          'Text, links, images, tables',
          'Meaningful markup & a11y',
          'Collecting user input',
          'SEO & accessibility essentials',
          'APIs, components, performance',
        ];
        const descs = [
          'Learn core elements, the page skeleton, and attributes.',
          'Compose rich content using text, media, and tables.',
          'Use semantic elements and improve accessibility.',
          'Build forms with proper labels, types, and validation.',
          'Follow best practices for SEO and accessibility.',
          'Use HTML5 APIs and optimize page performance.',
        ];
        return {'name': names[i], 'subtitle': subs[i], 'description': descs[i]};
      case 'CSS':
        const cssNames = [
          'Basics',
          'Layout Fundamentals',
          'Typography & Media',
          'Modern Layouts',
          'Architecture & Best Practices',
          'Advanced CSS',
        ];
        const cssSubs = [
          'Selectors, units, and applying styles',
          'Box model, display, positioning',
          'Fonts, backgrounds, and animations',
          'Flexbox, Grid, and responsive design',
          'Variables, BEM, and specificity',
          'Transitions, keyframes, modern features',
        ];
        const cssDescs = [
          'Style elements using selectors, colors, and units.',
          'Master layout with box model and positioning.',
          'Design readable, engaging content with typography and media.',
          'Build adaptive layouts using Flexbox and Grid.',
          'Structure large stylesheets with best practices.',
          'Add motion and modern techniques efficiently.',
        ];
        return {
          'name': cssNames[i],
          'subtitle': cssSubs[i],
          'description': cssDescs[i],
        };
      case 'JavaScript':
        const jsNames = [
          'Basics',
          'Control Flow',
          'Functions',
          'Data Structures',
          'Async JavaScript',
          'Advanced & Browser APIs',
        ];
        const jsSubs = [
          'Variables, types, and operators',
          'Branching and loops',
          'Declarations, arrows, and scope',
          'Arrays, objects, maps/sets',
          'Promises, async/await, fetching',
          'Modules, DOM, and events',
        ];
        const jsDescs = [
          'Write basic JS and understand the runtime.',
          'Control execution with conditions and loops.',
          'Reuse logic with functions and proper scope.',
          'Manage data using core JS structures.',
          'Handle asynchronous workflows and APIs.',
          'Interact with the browser efficiently.',
        ];
        return {
          'name': jsNames[i],
          'subtitle': jsSubs[i],
          'description': jsDescs[i],
        };
      case 'Java':
        const jNames = [
          'Getting Started',
          'Control Flow',
          'Functions & Methods',
          'Data Structures',
          'Object-Oriented Programming',
          'Advanced Concepts',
        ];
        const jSubs = [
          'Main method, syntax, variables',
          'Decisions and looping constructs',
          'Methods, return types, scope',
          'Arrays, collections, iteration',
          'Classes, inheritance, polymorphism',
          'Exceptions, I/O, packages',
        ];
        const jDescs = [
          'Start coding Java with the project structure.',
          'Control program flow with conditionals and loops.',
          'Organize code with methods and parameters.',
          'Use arrays and collections effectively.',
          'Design with core OOP principles.',
          'Work with files, modules, and robust errors.',
        ];
        return {
          'name': jNames[i],
          'subtitle': jSubs[i],
          'description': jDescs[i],
        };
      case 'Python':
        const pNames = [
          'Basics',
          'Control Flow',
          'Functions',
          'Data Structures',
          'Object-Oriented Programming',
          'Advanced Concepts',
        ];
        const pSubs = [
          'Syntax, variables, and types',
          'If/else, loops, and logic',
          'Defining and calling functions',
          'Lists, dicts, sets, iteration',
          'Classes and OOP pillars',
          'Errors, files, modules, tests',
        ];
        const pDescs = [
          'Get comfortable with Python basics.',
          'Write expressive control structures.',
          'Build reusable code with functions.',
          'Choose the right structure for data.',
          'Model programs with objects.',
          'Write maintainable, testable code.',
        ];
        return {
          'name': pNames[i],
          'subtitle': pSubs[i],
          'description': pDescs[i],
        };
      case 'C':
        const cNames = [
          'Basics',
          'Control Flow',
          'Functions & Pointers',
          'Data Structures',
          'Memory & Files',
          'Advanced C',
        ];
        const cSubs = [
          'Syntax, variables, and types',
          'If/else, loops, operators',
          'Functions, pointers, and scope',
          'Arrays, structs, enums',
          'Dynamic memory and file I/O',
          'Preprocessor and performance',
        ];
        const cDescs = [
          'Write and compile your first C programs.',
          'Control program flow and logic.',
          'Manage memory references correctly.',
          'Model data with C primitives.',
          'Work safely with memory and files.',
          'Use advanced C features effectively.',
        ];
        return {
          'name': cNames[i],
          'subtitle': cSubs[i],
          'description': cDescs[i],
        };
      default:
        return {
          'name': 'Level',
          'subtitle': 'Overview',
          'description': 'Learning content for this level.',
        };
    }
  }
}
