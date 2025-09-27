import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.cyanAccent),
            const SizedBox(width: 8),
            Text(
              'Leaderboard',
              style: GoogleFonts.pressStart2p(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B1C2C),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('xp', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No leaderboard data yet',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final data = users[index].data();
              String username = (data['username'] ?? '') as String;
              if (username.trim().isEmpty) {
                username = ((data['email'] ?? 'User') as String).split('@').first;
              }
              final xp = (data['xp'] ?? 0) as int;
              final badges = (data['badges'] ?? []) as List<dynamic>;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: index == 0
                        ? const Color(0xFFFFD700)
                        : index == 1
                        ? const Color(0xFFC0C0C0)
                        : index == 2
                        ? const Color(0xFFCD7F32)
                        : Colors.cyanAccent.withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.robotoMono(
                        color: index <= 2 ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    username,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.cyanAccent),
                      const SizedBox(width: 4),
                      Text(
                        '$xp XP',
                        style: GoogleFonts.robotoMono(color: Colors.white70),
                      ),
                      if (badges.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.emoji_events,
                          size: 16,
                          color: Colors.amberAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${badges.length} badge${badges.length == 1 ? '' : 's'}',
                          style: GoogleFonts.robotoMono(color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



