import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/progress_page.dart';
import 'pages/pronunciation_page.dart';

class AppRoutes {
  static const home = '/';
  static const progress = '/progress';
  static const pronunciation = '/pronunciation';
  static const lessons = '/lessons';
  static const settings = '/settings';
  
  static final routes = {
    home: (context) => const HomePage(),
    progress: (context) => const ProgressPage(),
    pronunciation: (context) => const PronunciationPage(),
  };
}