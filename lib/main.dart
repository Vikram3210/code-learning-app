import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Make sure this is auto-generated via Firebase CLI
import 'screens/splashscreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const CodeLearningApp());
}

class CodeLearningApp extends StatelessWidget {
  const CodeLearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Code Learning App',
      debugShowCheckedModeBanner: false,
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
      home: const SplashScreen(), // Start with splash, then navigate to WelcomeScreen
    );
  }
}
