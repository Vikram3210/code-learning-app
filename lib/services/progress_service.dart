import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  ProgressService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Returns a stream of per-language progress for the given user
  Stream<DocumentSnapshot<Map<String, dynamic>>> languageProgressStream(
    String userId,
    String languageName,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(languageName)
        .snapshots();
  }

  /// Reads the per-language progress once
  Future<DocumentSnapshot<Map<String, dynamic>>> getLanguageProgress(
    String userId,
    String languageName,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .doc(languageName)
        .get();
  }

  /// Marks a level as completed, increments XP, and unlocks the next level.
  /// Returns the updated progress data.
  Future<Map<String, dynamic>> completeLevel({
    required String userId,
    required String languageName,
    required int completedLevelIndex,
    required int totalLevels,
    int xpPerLevel = 100,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final progressRef = userRef.collection('progress').doc(languageName);

      return await _firestore.runTransaction((txn) async {
        final progressSnap = await txn.get(progressRef);
        final userSnap = await txn.get(userRef);

        int currentCompletedLevels = 0;
        int languageXp = 0;
        bool courseCompleted = false;

        if (progressSnap.exists) {
          final data = progressSnap.data() as Map<String, dynamic>;
          currentCompletedLevels = (data['completedLevels'] ?? 0) as int;
          languageXp = (data['xp'] ?? 0) as int;
          courseCompleted = (data['completed'] ?? false) as bool;
        }

        // Only allow marking the next level in order
        if (completedLevelIndex != currentCompletedLevels) {
          // Return existing data without changes
          return {
            'completedLevels': currentCompletedLevels,
            'xp': languageXp,
            'completed': courseCompleted,
          };
        }

        currentCompletedLevels += 1;
        languageXp += xpPerLevel;
        courseCompleted = currentCompletedLevels >= totalLevels;

        txn.set(progressRef, {
          'language': languageName,
          'completedLevels': currentCompletedLevels,
          'xp': languageXp,
          'completed': courseCompleted,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update user's aggregate XP and badges
        int totalXp = 0;
        List<dynamic> badges = [];
        String username = '';
        if (userSnap.exists) {
          final u = userSnap.data() as Map<String, dynamic>;
          totalXp = (u['xp'] ?? 0) as int;
          badges = (u['badges'] ?? []) as List<dynamic>;
          username = (u['username'] ?? '') as String;
        }
        totalXp += xpPerLevel;

        // Award badge on course completion if not already present
        if (courseCompleted) {
          final badgeId = 'completed_$languageName';
          final hasBadge = badges.any(
            (b) => (b is Map<String, dynamic>) && b['id'] == badgeId,
          );
          if (!hasBadge) {
            badges = List<dynamic>.from(badges)
              ..add({
                'id': badgeId,
                'title': 'Completed $languageName',
                'awardedAt': FieldValue.serverTimestamp(),
              });
          }
        }

        txn.set(userRef, {
          'xp': totalXp,
          'badges': badges,
          'username': username,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return {
          'completedLevels': currentCompletedLevels,
          'xp': languageXp,
          'completed': courseCompleted,
          'totalXp': totalXp,
        };
      });
    } catch (e) {
      print('ProgressService.completeLevel error: $e');
      print(
        'UserId: $userId, Language: $languageName, Level: $completedLevelIndex',
      );
      rethrow; // Re-throw to let the caller handle it
    }
  }

  /// Stream of the user's profile for XP, badges, streaks
  Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(
    String userId,
  ) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// List all per-language progress docs
  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  listLanguageProgress(String userId) async {
    final snap = await _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .get();
    return snap.docs;
  }

  /// Award daily streak/quest XP if not already claimed today.
  /// Returns updated fields { totalXp, streakCount, claimedToday }
  Future<Map<String, dynamic>> claimDailyQuest({
    required String userId,
    int dailyXp = 25,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);
    final now = DateTime.now().toUtc();
    final todayKey = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).toIso8601String();

    return _firestore.runTransaction((txn) async {
      final snap = await txn.get(userRef);
      int totalXp = 0;
      int streakCount = 0;
      String? lastActiveDayKey;
      String? lastClaimedDayKey;

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        totalXp = (data['xp'] ?? 0) as int;
        streakCount = (data['streakCount'] ?? 0) as int;
        lastActiveDayKey = (data['lastActiveDayKey'] ?? '') as String?;
        lastClaimedDayKey = (data['lastClaimedDayKey'] ?? '') as String?;
      }

      // If already claimed today, do nothing
      if (lastClaimedDayKey == todayKey) {
        return {
          'totalXp': totalXp,
          'streakCount': streakCount,
          'claimedToday': true,
        };
      }

      // Determine if streak continues
      final yesterday = DateTime.utc(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1));
      final yesterdayKey = yesterday.toIso8601String();
      if (lastActiveDayKey == yesterdayKey) {
        streakCount += 1;
      } else if (lastActiveDayKey == todayKey) {
        // same day active; keep streak
      } else {
        streakCount = 1; // reset streak starting today
      }

      totalXp += dailyXp;

      txn.set(userRef, {
        'xp': totalXp,
        'streakCount': streakCount,
        'lastActiveDayKey': todayKey,
        'lastClaimedDayKey': todayKey,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return {
        'totalXp': totalXp,
        'streakCount': streakCount,
        'claimedToday': true,
      };
    });
  }
}
