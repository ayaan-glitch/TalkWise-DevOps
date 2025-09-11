import 'package:flutter/material.dart';
import 'package:talkwise/pages/home_page.dart';
import 'package:talkwise/pages/progress_page.dart';
import 'package:talkwise/pages/pronunciation_page.dart';
import 'package:talkwise/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talkwise - Language Learning',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4B39EF),
          primary: const Color(0xFF4B39EF),
          secondary: const Color(0xFF39D2C0),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.home,
      routes: AppRoutes.routes,
    );
  }
}