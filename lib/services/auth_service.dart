import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../screens/home_screen.dart';
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      print('AuthService: Starting Google Sign-In');
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print('AuthService: Google Sign-In cancelled by user');
        return null;
      }

      print('AuthService: Google user obtained: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('AuthService: Signing in with credential');
      final userCredential = await _auth.signInWithCredential(credential);

      // Ensure user document exists/persist profile
      final user = userCredential.user;
      if (user != null) {
        print('AuthService: User signed in, ensuring user document');
        await UserService().ensureUserDocument(user);
        print('AuthService: User document ensured');
      }

      if (context.mounted) {
        print('AuthService: Navigating to home screen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Authentication Error'),
            content: Text("❌ ${e.message}"),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sign-in Failed'),
            content: Text("❌ Google sign-in failed: $e"),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
      return null;
    }
  }
}
