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
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final userRef = _firestore.collection('users').doc(userId);
        final progressRef = userRef.collection('progress').doc(languageName);

        return await _firestore.runTransaction((txn) async {
          final progressSnap = await txn.get(progressRef);
          final userSnap = await txn.get(userRef);

          int currentCompletedLevels = 0;
          int languageXp = 0;
          bool courseCompleted = false;

          // Initialize user variables early
          int totalXp = 0;
          List<dynamic> badges = [];
          String username = '';

          if (progressSnap.exists) {
            final data = progressSnap.data() as Map<String, dynamic>;
            currentCompletedLevels = (data['completedLevels'] ?? 0) as int;
            languageXp = (data['xp'] ?? 0) as int;
            courseCompleted = (data['completed'] ?? false) as bool;
          }

          // Only allow marking the next level in order
          print(
            '🔍 Level validation: completedLevelIndex=$completedLevelIndex, currentCompletedLevels=$currentCompletedLevels, courseCompleted=$courseCompleted',
          );
          if (completedLevelIndex != currentCompletedLevels) {
            print('❌ Level validation failed - returning existing data');
            // Return existing data without changes, but still check for badge if course is completed
            if (courseCompleted) {
              print('🎉 Course already completed - checking for badge');
              // Still award badge if not already present
              final badgeId = 'completed_$languageName';
              final hasBadge = badges.any(
                (b) => (b is Map<String, dynamic>) && b['id'] == badgeId,
              );
              if (!hasBadge) {
                print('🏆 Adding missing badge: $badgeId');
                badges = List<dynamic>.from(badges)
                  ..add({
                    'id': badgeId,
                    'title': 'Completed $languageName',
                    'awardedAt': FieldValue.serverTimestamp(),
                  });

                // Update user document with badge
                txn.set(userRef, {
                  'xp': totalXp,
                  'badges': badges,
                  'username': username,
                  'updatedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
            }
            return {
              'completedLevels': currentCompletedLevels,
              'xp': languageXp,
              'completed': courseCompleted,
            };
          }
          print('✅ Level validation passed');

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
          if (userSnap.exists) {
            final u = userSnap.data() as Map<String, dynamic>;
            totalXp = (u['xp'] ?? 0) as int;
            badges = (u['badges'] ?? []) as List<dynamic>;
            username = (u['username'] ?? '') as String;
          } else {
            // If user document doesn't exist, create it with basic structure
            username = 'User'; // Default username
          }
          totalXp += xpPerLevel;

          // Award badge on course completion if not already present
          if (courseCompleted) {
            print('🎉 Course completed! Awarding badge for $languageName');
            print(
              'Current completed levels: $currentCompletedLevels, Total levels: $totalLevels',
            );
            final badgeId = 'completed_$languageName';
            final hasBadge = badges.any(
              (b) => (b is Map<String, dynamic>) && b['id'] == badgeId,
            );
            if (!hasBadge) {
              print('🏆 Adding new badge: $badgeId');
              badges = List<dynamic>.from(badges)
                ..add({
                  'id': badgeId,
                  'title': 'Completed $languageName',
                  'awardedAt': FieldValue.serverTimestamp(),
                });
            } else {
              print('⚠️ Badge already exists: $badgeId');
            }
          } else {
            print(
              '❌ Course not completed yet. Levels: $currentCompletedLevels/$totalLevels',
            );
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
        retryCount++;
        print('ProgressService.completeLevel error (attempt $retryCount): $e');
        print(
          'UserId: $userId, Language: $languageName, Level: $completedLevelIndex',
        );

        if (retryCount >= maxRetries) {
          // If all retries failed, try a simpler approach without transaction
          print('All retries failed, attempting non-transactional save...');
          try {
            return await _completeLevelWithoutTransaction(
              userId: userId,
              languageName: languageName,
              completedLevelIndex: completedLevelIndex,
              totalLevels: totalLevels,
              xpPerLevel: xpPerLevel,
            );
          } catch (fallbackError) {
            print('Fallback method also failed: $fallbackError');
            // Return a basic response to prevent app crash
            return {
              'completedLevels': 0,
              'xp': 0,
              'completed': false,
              'totalXp': 0,
            };
          }
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    // This should never be reached, but just in case
    throw Exception('Failed to complete level after $maxRetries attempts');
  }

  /// Fallback method to complete level without transaction
  Future<Map<String, dynamic>> _completeLevelWithoutTransaction({
    required String userId,
    required String languageName,
    required int completedLevelIndex,
    required int totalLevels,
    int xpPerLevel = 100,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final progressRef = userRef.collection('progress').doc(languageName);

      // Get current progress
      final progressSnap = await progressRef.get();
      int currentCompletedLevels = 0;
      int languageXp = 0;
      bool courseCompleted = false;

      // Initialize user variables early
      int totalXp = 0;
      List<dynamic> badges = [];
      String username = '';

      if (progressSnap.exists) {
        final data = progressSnap.data() as Map<String, dynamic>;
        currentCompletedLevels = (data['completedLevels'] ?? 0) as int;
        languageXp = (data['xp'] ?? 0) as int;
        courseCompleted = (data['completed'] ?? false) as bool;
      }

      // Only allow marking the next level in order
      print(
        '🔍 Level validation (fallback): completedLevelIndex=$completedLevelIndex, currentCompletedLevels=$currentCompletedLevels, courseCompleted=$courseCompleted',
      );
      if (completedLevelIndex != currentCompletedLevels) {
        print('❌ Level validation failed (fallback) - returning existing data');
        // Still check for badge if course is completed
        if (courseCompleted) {
          print('🎉 Course already completed - checking for badge (fallback)');
          final badgeId = 'completed_$languageName';
          final hasBadge = badges.any(
            (b) => (b is Map<String, dynamic>) && b['id'] == badgeId,
          );
          if (!hasBadge) {
            print('🏆 Adding missing badge: $badgeId (fallback)');
            badges = List<dynamic>.from(badges)
              ..add({
                'id': badgeId,
                'title': 'Completed $languageName',
                'awardedAt': FieldValue.serverTimestamp(),
              });

            // Update user document with badge
            await userRef.set({
              'xp': totalXp,
              'badges': badges,
              'username': username,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
          }
        }
        return {
          'completedLevels': currentCompletedLevels,
          'xp': languageXp,
          'completed': courseCompleted,
        };
      }
      print('✅ Level validation passed (fallback)');

      currentCompletedLevels += 1;
      languageXp += xpPerLevel;
      courseCompleted = currentCompletedLevels >= totalLevels;

      // Update progress
      await progressRef.set({
        'language': languageName,
        'completedLevels': currentCompletedLevels,
        'xp': languageXp,
        'completed': courseCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update user's aggregate XP and badges
      final userSnap = await userRef.get();

      if (userSnap.exists) {
        final u = userSnap.data() as Map<String, dynamic>;
        totalXp = (u['xp'] ?? 0) as int;
        badges = (u['badges'] ?? []) as List<dynamic>;
        username = (u['username'] ?? '') as String;
      } else {
        // If user document doesn't exist, create it with basic structure
        username = 'User'; // Default username
      }

      totalXp += xpPerLevel;

      // Award badge on course completion if not already present
      if (courseCompleted) {
        print(
          '🎉 Course completed! Awarding badge for $languageName (fallback method)',
        );
        print(
          'Current completed levels: $currentCompletedLevels, Total levels: $totalLevels',
        );
        final badgeId = 'completed_$languageName';
        final hasBadge = badges.any(
          (b) => (b is Map<String, dynamic>) && b['id'] == badgeId,
        );
        if (!hasBadge) {
          print('🏆 Adding new badge: $badgeId (fallback method)');
          badges = List<dynamic>.from(badges)
            ..add({
              'id': badgeId,
              'title': 'Completed $languageName',
              'awardedAt': FieldValue.serverTimestamp(),
            });
        } else {
          print('⚠️ Badge already exists: $badgeId (fallback method)');
        }
      } else {
        print(
          '❌ Course not completed yet. Levels: $currentCompletedLevels/$totalLevels (fallback method)',
        );
      }

      await userRef.set({
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
    } catch (e) {
      print('ProgressService._completeLevelWithoutTransaction error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');

      // Return a safe fallback response instead of rethrowing
      return {'completedLevels': 0, 'xp': 0, 'completed': false, 'totalXp': 0};
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
