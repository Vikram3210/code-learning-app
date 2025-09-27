import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> ensureUserDocument(User user, {String? username}) async {
    try {
      print('UserService: Ensuring user document for ${user.uid}');
      final users = _firestore.collection('users');
      final doc = users.doc(user.uid);
      final snap = await doc.get();

      if (!snap.exists) {
        print('UserService: Creating new user document');
        await doc.set({
          'uid': user.uid,
          'email': user.email,
          'username': username ?? (user.displayName ?? user.email ?? 'User'),
          'xp': 0,
          'badges': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('UserService: User document created successfully');
      } else {
        print('UserService: User document already exists');
        if (username != null) {
          await doc.set({
            'username': username,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
    } catch (e) {
      print('UserService: Error ensuring user document: $e');
      rethrow;
    }
  }
}
