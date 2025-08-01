// lib/home_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';

import 'cloud_sync_manager.dart';
import 'ordner_page.dart';
import 'calendar.dart';
import 'year_beleg.dart';
import 'LandingPage.dart';

const _earliestYear = 2021;

class HomePage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const HomePage({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _cloudEnabled = false;
  late final List<int> _years;
  OverlayEntry? _uploadOverlay;

  @override
  void initState() {
    super.initState();
    _years = [
      for (int y = DateTime.now().year; y >= _earliestYear; y--) y,
    ];
    _initializeSync();
  }

  Future<void> _initializeSync() async {
    // Remote-Flag aus Firestore holen
    final enabled = await CloudSyncManager.fetchRemoteSyncFlag();
    setState(() => _cloudEnabled = enabled);

    // Download aus der Cloud entfernt —
    // Dateien werden jetzt folderweise beim Öffnen geladen.
  }

  Future<void> _toggleCloudSync() async {
    if (_cloudEnabled) {
      // Deaktivieren: Remote-Flag ausschalten
      await CloudSyncManager.setRemoteSyncFlag(false);
      setState(() => _cloudEnabled = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud-Sync deaktiviert')),
      );
    } else {
      // Aktivieren: erst lokal hochladen
      await CloudSyncManager.uploadLocalToCloud();
      // Pop-up anzeigen, wenn Upload abgeschlossen ist
      _showUploadNotification();

      // Remote-Flag setzen
      await CloudSyncManager.setRemoteSyncFlag(true);
      setState(() => _cloudEnabled = true);

      // Download entfernt — die Dateien kommen beim Öffnen der Ordner.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cloud-Sync aktiviert und synchronisiert')),
      );
    }
  }

  void _showUploadNotification() {
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    _uploadOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top,
        left: 0,
        right: 0,
        child: _UploadNotification(
          onDismissed: () {
            _uploadOverlay?.remove();
            _uploadOverlay = null;
          },
        ),
      ),
    );
    overlay.insert(_uploadOverlay!);
  }

  Future<void> _openLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('last_opened_doc');
    if (path != null && await File(path).exists()) {
      final name = path.split(Platform.pathSeparator).last;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öffne zuletzt geöffneten Beleg: $name')),
      );
      await OpenFile.open(path);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein zuletzt geöffneter Beleg gefunden')),
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
                          MaterialPageRoute(builder: (_) => YearBelegPage(year: y)),
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
              subtitle: 'Direkter Zugang zum zuletzt geöffneten Beleg',
              onTap: _openLastOpened,
            ),
            const SizedBox(height: 12),
            _PillButton(
              assetPath: 'assets/cloud_server.png',
              title: _cloudEnabled ? 'Cloud-Sync aktiviert' : 'Cloud-Speicher',
              subtitle: _cloudEnabled
                  ? 'Alle Dateien in der Cloud gesichert'
                  : 'Erstmalige Sicherung in die Cloud',
              onTap: _toggleCloudSync,
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

/// Ein kleines Overlay, das oben ein Popup anzeigt,
/// mit Text und einer progress-animierten Leiste.
class _UploadNotification extends StatefulWidget {
  final VoidCallback onDismissed;
  const _UploadNotification({required this.onDismissed});

  @override
  State<_UploadNotification> createState() => _UploadNotificationState();
}

class _UploadNotificationState extends State<_UploadNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Animation von v=1.0 → 0.0 in 3 Sekunden
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
      value: 1.0,
    )..reverse().whenComplete(() {
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: const Text(
              'Datei wurde erfolgreich hochgeladen',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black),
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return LinearProgressIndicator(
                value: _controller.value,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation(Colors.green),
                minHeight: 4,
              );
            },
          ),
        ],
      ),
    );
  }
}
