import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'verify_email_screen.dart';
import '../services/user_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool isLoading = false;

  final passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).{6,}$',
  );

  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  Future<void> registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Ensure Firestore profile immediately
      final u = userCredential.user;
      if (u != null) {
        await UserService().ensureUserDocument(
          u,
          username: _usernameController.text.trim(),
        );
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            userCredential: userCredential,
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => isLoading = false);
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E2A38),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.redAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  e.message ?? "Registration failed",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text(
                "OK",
                style: TextStyle(color: Colors.cyanAccent),
              ),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1C2C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1C2C),
        title: const Text("Register"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText(
                      'Create Your CodeHub Avatar!',
                      textStyle: GoogleFonts.pressStart2p(
                        color: Colors.cyanAccent,
                        fontSize: 16,
                      ),
                      speed: const Duration(milliseconds: 80),
                    ),
                  ],
                  totalRepeatCount: 1,
                ),
                const SizedBox(height: 30),

                // Username
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white12,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Enter a username' : null,
                ),

                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.white),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white12,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter an email';
                    } else if (!emailRegex.hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(color: Colors.white),
                    helperText:
                        'Min 6 chars, 1 upper, 1 lower, 1 digit, 1 special',
                    helperStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white12,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter a password';
                    } else if (!passwordRegex.hasMatch(value)) {
                      return 'Weak password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 30),

                isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.cyanAccent,
                        ),
                      )
                    : ElevatedButton(
                        onPressed: registerUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("🚀 Register Now"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
