// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'learning_roadmap_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Map<String, dynamic>> programmingLanguages = const [
    {
      'name': 'Python',
      'icon': '🐍',
      'description': 'Versatile scripting and data science',
      'color': Color(0xFF3776AB),
      'difficulty': 'Beginner',
    },
    {
      'name': 'Java',
      'icon': '☕',
      'description': 'Enterprise apps and Android',
      'color': Color(0xFFED8B00),
      'difficulty': 'Intermediate',
    },
    {
      'name': 'HTML',
      'icon': '📄',
      'description': 'Structure the web',
      'color': Color(0xFFE34F26),
      'difficulty': 'Beginner',
    },
    {
      'name': 'CSS',
      'icon': '🎨',
      'description': 'Style the web',
      'color': Color(0xFF1572B6),
      'difficulty': 'Beginner',
    },
    {
      'name': 'JavaScript',
      'icon': '⚡',
      'description': 'Interactive web programming',
      'color': Color(0xFFF7DF1E),
      'difficulty': 'Intermediate',
    },
    {
      'name': 'C',
      'icon': '🔧',
      'description': 'Systems programming fundamentals',
      'color': Color(0xFF00599C),
      'difficulty': 'Advanced',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.videogame_asset, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text(
              "CodeHub Arena",
              style: GoogleFonts.pressStart2p(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B1C2C),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Leaderboard',
            icon: const Icon(Icons.emoji_events, color: Colors.cyanAccent),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Center(
              child: Column(
                children: [
                  Text(
                    'Select Your Path',
                    style: GoogleFonts.pressStart2p(
                      fontSize: 16,
                      color: Colors.cyanAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a language to start your quest',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Language Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // Slightly taller cards to prevent overflow on small screens
                childAspectRatio: 0.95,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: programmingLanguages.length,
              itemBuilder: (context, index) {
                final language = programmingLanguages[index];
                return _buildLanguageCard(context, language);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context,
    Map<String, dynamic> language,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LearningRoadmapScreen(
              languageName: language['name'],
              languageIcon: language['icon'],
              languageColor: language['color'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              language['color'].withOpacity(0.8),
              language['color'].withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: language['color'].withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(language['icon'], style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(
                language['name'],
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Flexible(
                child: Text(
                  language['description'],
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  language['difficulty'],
                  style: GoogleFonts.robotoMono(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
