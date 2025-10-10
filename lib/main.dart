// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:talkwise/pages/home_page.dart';
// import 'package:talkwise/pages/pronunciation_page.dart';
// import 'package:talkwise/pages/progress_page.dart';
// import 'package:talkwise/pages/settings_page.dart';
// import 'app_routes.dart';
// import 'package:talkwise/pages/theme_provider.dart';
// import 'package:talkwise/pages/pronunciation_backend.dart';

// void main() {
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => ThemeProvider()),
//         ChangeNotifierProvider(create: (context) => PronunciationBackend()),
//       ],
//       child: Builder(
//         builder: (context) {
//           final themeProvider = Provider.of<ThemeProvider>(context);
          
//           return MaterialApp(
//             title: 'TalkWise',
//             theme: ThemeData(
//               primarySwatch: Colors.blue,
//               brightness: Brightness.light,
//             ),
//             darkTheme: ThemeData(
//               primarySwatch: Colors.blue,
//               brightness: Brightness.dark,
//             ),
//             themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
//             initialRoute: AppRoutes.home,
//             routes: {
//               AppRoutes.home: (context) => HomePage(),
//               AppRoutes.pronunciation: (context) => PronunciationPage(),
//               AppRoutes.progress: (context) => ProgressPage(),
//               AppRoutes.settings: (context) => SettingsScreen(),
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkwise/pages/home_page.dart';
import 'package:talkwise/pages/pronunciation_page.dart';
import 'package:talkwise/pages/progress_page.dart';
import 'package:talkwise/pages/settings_page.dart';
import 'package:talkwise/pages/chatbot_page.dart';
import 'app_routes.dart';
import 'package:talkwise/pages/theme_provider.dart';
import 'package:talkwise/pages/pronunciation_backend.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => PronunciationBackend()),
      ],
      child: Builder(
        builder: (context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          
          return MaterialApp(
            title: 'TalkWise',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.light,
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: Brightness.dark,
            ),
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: AppRoutes.home,
            routes: AppRoutes.routes,
          );
        },
      ),
    );
  }
}