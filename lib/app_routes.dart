// app_routes.dart
import 'pages/home_page.dart';
import 'pages/progress_page.dart';
import 'pages/pronunciation_page.dart';
import 'pages/settings_page.dart';
import 'pages/chatbot_page.dart';
import 'pages/lessons_page.dart'; // Make sure this import exists
import 'pages/login_page.dart';
import 'pages/signup_page.dart';

class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/';
  static const progress = '/progress';
  static const pronunciation = '/pronunciation';
  static const lessons = '/lessons';
  static const settings = '/settings';
  static const chatbot = '/chatbot';

  static final routes = {
    login: (context) => const LoginPage(),
    signup: (context) => const SignupPage(),
    home: (context) => const HomePage(),
    progress: (context) => const ProgressPage(),
    pronunciation: (context) => const PronunciationPage(),
    lessons: (context) => const LessonsPage(), // Make sure this is included
    settings: (context) => const SettingsScreen(),
    chatbot: (context) => const ChatbotPage(),
  };
}
