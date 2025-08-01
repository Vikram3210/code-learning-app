import 'package:flutter/material.dart';
import 'screens/splashscreen.dart';

void main() {
  runApp(const CodeLearningApp());
}

class CodeLearningApp extends StatelessWidget {
  const CodeLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Learning App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B1C2C),
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF4FC3F7),  // Primary Accent
          onPrimary: Colors.white,
          secondary: const Color(0xFF0288D1), // Shadow or darker blue
          onSecondary: Colors.white,
          background: const Color(0xFF0B1C2C), // Background
          onBackground: const Color(0xFF4FC3F7), // Text and Icons
          surface: const Color(0xFF0B1C2C),
          onSurface: const Color(0xFF4FC3F7),
          error: Colors.red,
          onError: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF4FC3F7)),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
