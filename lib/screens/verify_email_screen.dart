import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';

class VerifyEmailScreen extends StatefulWidget {
  final UserCredential userCredential;
  final String email;
  final String username;

  const VerifyEmailScreen({
    super.key,
    required this.userCredential,
    required this.email,
    required this.username,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}


class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isChecking = false;

  @override
  void initState() {
    super.initState();
    sendVerificationEmail();
  }

  // Send verification email to the user
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      print("✅ Verification email sent.");
    }
  }

  // Check if user has verified their email
  Future<void> checkVerificationStatus() async {
    setState(() => isChecking = true);
    await _auth.currentUser?.reload(); // refresh user data
    final user = _auth.currentUser;

    if (user != null && user.emailVerified) {
      print("✅ Email verified!");

      // Save user to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': widget.email,
        'username': widget.username,
        'createdAt': Timestamp.now(),
      });

      // Navigate to welcome screen
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    } else {
      setState(() => isChecking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Email not verified yet.")),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      appBar: AppBar(
        title: const Text("Verify Email"),
        backgroundColor: const Color(0xFF0B1C2C),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    '🎯 A verification link has been sent to your email.',
                    textStyle: GoogleFonts.robotoMono(
                        fontSize: 16, color: Colors.white),
                    speed: const Duration(milliseconds: 60),
                  ),
                  TyperAnimatedText(
                    '⚡ Verify to unlock your CodeHub account!',
                    textStyle: GoogleFonts.robotoMono(
                        fontSize: 16, color: Colors.cyanAccent),
                    speed: const Duration(milliseconds: 70),
                  ),
                ],
                totalRepeatCount: 1,
              ),
              const SizedBox(height: 30),
              isChecking
                  ? const CircularProgressIndicator(
                color: Colors.cyanAccent,
              )
                  : ElevatedButton.icon(
                icon: const Icon(Icons.verified),
                label: const Text("✅ I have verified"),
                onPressed: checkVerificationStatus,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
