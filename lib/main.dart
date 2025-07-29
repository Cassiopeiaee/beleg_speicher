// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:beleg_speicher/LandingPage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Beleg Speicher',
      // 1) Delegates, um Datumspicker & Co. zu lokalisieren
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // 2) Unterstützte Sprachen
      supportedLocales: const [
        Locale('de'), // Deutsch
        Locale('en'), // Englisch (Fallback)
      ],
      // 3) Standard-Sprache
      locale: const Locale('de'),

      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: Colors.white,
          onPrimary: Colors.purple.shade700,
          secondary: Colors.purple.shade400,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
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
      home: const LandingPage(),
    );
  }
}
