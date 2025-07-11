import 'package:flutter/material.dart';
// 1. richtigen Pfad zu deiner LandingPage-Datei verwenden:
import 'package:beleg_speicher/LandingPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beleg Speicher',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Colors.white,                  // ehemals background
          onPrimary: Colors.purple.shade700,      // Text/Icon auf primary
          secondary: Colors.purple.shade400,
          onSecondary: Colors.white,
          surface: Colors.white,                  // ersetzt background
          onSurface: Colors.black,                // ersetzt onBackground
          error: Colors.red,
          onError: Colors.white,
          background: Colors.white,               // kannst auch surface verwenden
          onBackground: Colors.black,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.purple.shade400,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade400,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      // 2. hier deine LandingPage als Startseite setzen:
      home: const LandingPage(),
    );
  }
}
