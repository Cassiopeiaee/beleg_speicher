// lib/home_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beleg_speicher/LandingPage.dart';
import 'package:beleg_speicher/ordner_page.dart';
import 'package:beleg_speicher/calendar.dart';
import 'package:beleg_speicher/year_beleg.dart';

class HomePage extends StatefulWidget {
  final String firstName;
  final String lastName;

  HomePage({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _earliestYear = 2021;
  static const _prefsCloudKey = 'cloud_sync_enabled';
  bool _cloudEnabled = false;
  late final List<int> _years;

  @override
  void initState() {
    super.initState();
    _years = [
      for (int y = DateTime.now().year; y >= _earliestYear; y--) y,
    ];
    _loadCloudFlag();
  }

  Future<void> _loadCloudFlag() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _cloudEnabled = prefs.getBool(_prefsCloudKey) ?? false;
    });
  }

  Future<void> _enableCloudSync() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_cloudEnabled) {
      // 1) Firebase initialisieren
      await Firebase.initializeApp();
      // 2) Alle bisherigen Dateien hochladen
      final storage = FirebaseStorage.instance;
      // Keys in SharedPreferences mit 'docs_<folder>' sammeln
      for (final key in prefs.getKeys()) {
        if (key.startsWith('docs_')) {
          final folderName = key.substring(5);
          final paths = prefs.getStringList(key) ?? [];
          for (final path in paths) {
            final file = File(path);
            if (await file.exists()) {
              final ref = storage
                  .ref('backups/$folderName/${file.uri.pathSegments.last}');
              try {
                await ref.putFile(file);
              } catch (e) {
                // Fehler einzelner Dateien protokollieren, aber weitermachen
                debugPrint('Upload $path fehlgeschlagen: $e');
              }
            }
          }
        }
      }
      // 3) Flag setzen
      await prefs.setBool(_prefsCloudKey, true);
      setState(() => _cloudEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud-Sync aktiviert und alle Dateien gesichert')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud-Sync ist bereits aktiviert')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            splashRadius: 24,
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // noch leer, Import-Logik sitzt in OrdnerPage
        },
        backgroundColor: Colors.purple.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Hinzufügen', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Herzlich Willkommen',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.black),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              color: Colors.purple.shade400,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            // Suchfeld
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.purple),
                  hintText: 'Suche',
                  hintStyle: TextStyle(color: Colors.black87),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            // Jahres-Pill-Buttons
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _years.map((y) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _YearPillButton(
                      year: y,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => YearBelegPage(year: y),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 2, color: Colors.purple.shade400),
            const SizedBox(height: 16),
            // Feature-Pills
            _PillButton(
              assetPath: 'assets/calendar_home.png',
              title: 'Kalender',
              subtitle: 'Einsehen von Belegen anhand des Datum',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalendarPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _PillButton(
              assetPath: 'assets/folder_home.png',
              title: 'Ordner',
              subtitle: 'Einsehen von Belegen in einem Ordner',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const OrdnerPage()),
                );
              },
            ),
            const SizedBox(height: 12),
            _PillButton(
              assetPath: 'assets/time_home.png',
              title: 'Zuletzt geöffnet',
              subtitle: 'Einsehen des zuletzt geöffneten Beleg',
              onTap: () {
                // hier könntest du später die InsideOrdnerPage für letzte 7 Tage aufrufen
              },
            ),
            const SizedBox(height: 12),
            _PillButton(
              assetPath: 'assets/cloud_server.png',
              title: _cloudEnabled ? 'Cloud-Sync aktiviert' : 'Cloud-Speicher',
              subtitle: _cloudEnabled
                  ? 'Alle Dateien in der Cloud gesichert'
                  : 'Erstmalige Sicherung in die Cloud',
              onTap: _enableCloudSync,
            ),
          ],
        ),
      ),
    );
  }
}

class _YearPillButton extends StatelessWidget {
  final int year;
  final VoidCallback onTap;
  const _YearPillButton({required this.year, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            '$year',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String assetPath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _PillButton({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Image.asset(assetPath, width: 32, height: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black)),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: 14, color: Colors.black.withAlpha(204)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
