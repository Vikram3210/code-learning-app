import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated title
            AnimatedTextKit(
              animatedTexts: [
                TyperAnimatedText(
                  'CodeHub',
                  textStyle: GoogleFonts.pressStart2p(
                    fontSize: 32,
                    color: const Color(0xFF4FC3F7),
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              isRepeatingAnimation: false,
            ),
            const SizedBox(height: 20),
            Text(
              'Learn, Practice, and Master Programming',
              textAlign: TextAlign.center,
              style: GoogleFonts.robotoMono(
                fontSize: 18,
                color: const Color(0xFF4FC3F7),
              ),
            ),
            const SizedBox(height: 50),

            // Login button animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 50),
                    child: child,
                  ),
                );
              },
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to Login screen
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: const Color(0xFF4FC3F7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF0B1C2C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Register button animation
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1200),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 50),
                    child: child,
                  ),
                );
              },
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Navigate to Register screen
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: Color(0xFF4FC3F7)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(fontSize: 20, color: Color(0xFF4FC3F7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
