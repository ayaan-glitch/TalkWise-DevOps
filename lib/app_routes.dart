/* import 'pages/home_page.dart';
import 'pages/progress_page.dart';
import 'pages/pronunciation_page.dart';
import 'pages/settings_page.dart';
import 'pages/chatbot_page.dart';

class AppRoutes {
  static const home = '/';
  static const progress = '/progress';
  static const pronunciation = '/pronunciation';
  static const lessons = '/lessons';
  static const settings = '/settings';
  static const chatbot = '/chatbot';
  
  static final routes = {
    home: (context) => const HomePage(),
    progress: (context) => const ProgressPage(),
    pronunciation: (context) => const PronunciationPage(),
    settings: (context) => const SettingsScreen(),
    chatbot: (context) => const ChatbotPage(),
  };
} */

// app_routes.dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/progress_page.dart';
import 'pages/pronunciation_page.dart';
import 'pages/settings_page.dart';
import 'pages/chatbot_page.dart';
import 'pages/lessons_page.dart'; // Add this import

class AppRoutes {
  static const home = '/';
  static const progress = '/progress';
  static const pronunciation = '/pronunciation';
  static const lessons = '/lessons';
  static const settings = '/settings';
  static const chatbot = '/chatbot';
  
  static final routes = {
    home: (context) => const HomePage(),
    progress: (context) => const ProgressPage(),
    pronunciation: (context) => const PronunciationPage(),
    lessons: (context) => const LessonsPage(), // Add this route
    settings: (context) => const SettingsScreen(),
    chatbot: (context) => const ChatbotPage(),
  };
}