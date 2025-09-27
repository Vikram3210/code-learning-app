import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/progress_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final ProgressService _progressService = ProgressService();

  bool _loadingProgress = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _languageProgress = [];

  @override
  void initState() {
    super.initState();
    _loadLanguageProgress();
  }

  Future<void> _loadLanguageProgress() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _loadingProgress = false);
        return;
      }
      _languageProgress = await _progressService.listLanguageProgress(user.uid);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load language progress: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingProgress = false);
    }
  }

  Future<void> _claimDaily() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final result = await _progressService.claimDailyQuest(userId: user.uid);
    final streak = result['streakCount'] as int;
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Daily quest claimed! Streak: $streak'),
        backgroundColor: Colors.cyanAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.person, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text(
              'Player Profile',
              style: GoogleFonts.pressStart2p(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B1C2C),
        elevation: 0,
      ),
      body: user == null
          ? const Center(
              child: Text('Not logged in', style: TextStyle(color: Colors.white70)),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _progressService.userProfileStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  );
                }
                final data = snapshot.data?.data() ?? {};
                final username = (data['username'] ?? user.email ?? 'User') as String;
                final xp = (data['xp'] ?? 0) as int;
                final badges = (data['badges'] ?? []) as List<dynamic>;
                final streak = (data['streakCount'] ?? 0) as int;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      LayoutBuilder(builder: (context, constraints) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                            child: Text(
                              username.isNotEmpty ? username[0].toUpperCase() : 'U',
                              style: GoogleFonts.robotoMono(
                                fontSize: 20,
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Icon(Icons.star, size: 16, color: Colors.cyanAccent),
                                    Text('$xp XP', style: GoogleFonts.robotoMono(color: Colors.white70)),
                                    Icon(Icons.local_fire_department, size: 16, color: Colors.orangeAccent),
                                    Text('Streak: $streak', style: GoogleFonts.robotoMono(color: Colors.white70)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 140),
                            child: ElevatedButton.icon(
                              onPressed: _claimDaily,
                              icon: const Icon(Icons.flash_on, size: 16),
                              label: const Text('Daily Quest', overflow: TextOverflow.ellipsis),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.cyanAccent,
                                foregroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      );
                      }),

                      const SizedBox(height: 20),

                      // Badges
                      Text(
                        'Badges',
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (badges.isEmpty)
                        const Text('No badges yet', style: TextStyle(color: Colors.white54))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: badges.map((b) {
                            final map = (b as Map<String, dynamic>);
                            final title = (map['title'] ?? 'Badge') as String;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.emoji_events, color: Colors.amberAccent, size: 18),
                                  const SizedBox(width: 6),
                                  Text(title, style: GoogleFonts.robotoMono(color: Colors.white)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                      const SizedBox(height: 20),

                      // Per-language progress
                      Text(
                        'Your Languages',
                        style: GoogleFonts.robotoMono(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _loadingProgress
                          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                          : (_languageProgress.isEmpty
                              ? const Text('No progress yet', style: TextStyle(color: Colors.white54))
                              : Column(
                                  children: _languageProgress.map((doc) {
                                    final d = doc.data();
                                    final lang = (d['language'] ?? doc.id) as String;
                                    final completedLevels = (d['completedLevels'] ?? 0) as int;
                                    final languageXp = (d['xp'] ?? 0) as int;
                                    final completed = (d['completed'] ?? false) as bool;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(lang, style: GoogleFonts.robotoMono(color: Colors.white, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Levels: $completedLevels • XP: $languageXp',
                                                  style: GoogleFonts.robotoMono(color: Colors.white70, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: completed ? Colors.green.withOpacity(0.2) : Colors.white12,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              completed ? 'Completed' : 'In Progress',
                                              style: GoogleFonts.robotoMono(
                                                color: completed ? Colors.green : Colors.white70,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                )),
                    ],
                  ),
                );
              },
            ),
    );
  }
}


