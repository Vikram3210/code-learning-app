import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:delayed_display/delayed_display.dart';

import 'register_screen.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool isLoading = false;

  Future<void> loginUser() async {
    setState(() => isLoading = true);

    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      showCustomSnackBar("⚠️ Please enter email and password", bgColor: Colors.orange, icon: Icons.warning);
      setState(() => isLoading = false);
      return;
    }

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      showCustomSnackBar("❌ ${e.message}", bgColor: Colors.redAccent, icon: Icons.error);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void showCustomSnackBar(String message, {Color bgColor = Colors.redAccent, IconData? icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) Icon(icon, color: Colors.white),
            if (icon != null) const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/logo.jpg', height: 120),
              const SizedBox(height: 20),

              AnimatedTextKit(
                animatedTexts: [
                  TyperAnimatedText(
                    'CodeHub',
                    textStyle: GoogleFonts.pressStart2p(
                      fontSize: 28,
                      color: const Color(0xFF4FC3F7),
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
                isRepeatingAnimation: false,
              ),

              const SizedBox(height: 16),

              Text(
                'Learn, Practice, and Master Programming',
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  color: const Color(0xFF4FC3F7),
                ),
              ),

              const SizedBox(height: 30),

              slideFade(
                delay: 300,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: const TextStyle(color: Colors.white),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              slideFade(
                delay: 500,
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.white),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white12,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              slideFade(
                delay: 700,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.cyanAccent)
                    : ElevatedButton(
                  onPressed: loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("🚀 Login"),
                ),
              ),

              const SizedBox(height: 16),

              slideFade(
                delay: 900,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text.rich(
                    TextSpan(
                      text: "Don’t have an account? ",
                      style: TextStyle(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              slideFade(
                delay: 1100,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final user = await AuthService().signInWithGoogle(context);
                    if (user == null) {
                      showCustomSnackBar("❌ Google Sign-In failed", icon: Icons.error);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    backgroundColor: Colors.white10,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Image.asset('assets/google_logo.png', height: 26, width: 26),
                  label: const Text(
                    "Continue with Google",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget slideFade({required Widget child, required int delay}) {
    return DelayedDisplay(
      delay: Duration(milliseconds: delay),
      slidingBeginOffset: const Offset(0, 0.3),
      fadeIn: true,
      child: child,
    );
  }
}
