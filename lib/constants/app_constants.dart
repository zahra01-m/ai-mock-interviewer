import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // ─── Groq API ────────────────────────────────────────────────────────────
  // API key .env file se load hogi — source code mein hardcoded nahi hai
  // Project root mein .env file banao:
  //   GROQ_API_KEY=gsk_your_actual_key_here
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  static const String groqBaseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel   = 'llama-3.3-70b-versatile';

  // ─── App Info ─────────────────────────────────────────────────────────────
  static const String appName    = 'AI Mock Interviewer';
  static const String appVersion = '1.0.0';

  // ─── Interview Settings ───────────────────────────────────────────────────
  static const List<int> interviewDurations = [5, 10, 15, 30]; // minutes
  static const int questionTimeLimit = 120; // seconds per question
  static const int hintPenalty       = 2;   // score deduction for using hint

  // ─── Topics ───────────────────────────────────────────────────────────────
  static const List<String> topics = [
    'DSA',
    'OOP',
    'Operating System',
    'DBMS',
    'Computer Networks',
    'Web Development',
    'HR / Behavioral',
    'Company Specific',
  ];

  // ─── Difficulty Levels ────────────────────────────────────────────────────
  static const List<String> levels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Mock Final Round',
  ];

  // ─── Firestore Collections ────────────────────────────────────────────────
  static const String usersCollection       = 'users';
  static const String interviewsCollection  = 'interviews';
  static const String leaderboardCollection = 'leaderboard';
  static const String feedbackCollection    = 'feedback';

  // ─── Shared Preferences Keys ─────────────────────────────────────────────
  static const String themeKey       = 'isDarkMode';
  static const String onboardingKey  = 'onboardingDone';
  static const String languageKey    = 'language';
}