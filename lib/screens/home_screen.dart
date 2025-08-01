// lib/screens/home_screen.dart

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade900,
      appBar: AppBar(
        title: const Text("Welcome to CodeHub"),
        backgroundColor: Colors.teal,
      ),
      body: const Center(
        child: Text(
          "🎉 You're logged in!",
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
