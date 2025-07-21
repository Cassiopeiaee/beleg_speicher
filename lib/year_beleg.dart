// lib/year_beleg.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';

class YearBelegPage extends StatefulWidget {
  final int year;
  const YearBelegPage({super.key, required this.year});

  @override
  State<YearBelegPage> createState() => _YearBelegPageState();
}

class _YearBelegPageState extends State<YearBelegPage> {
  bool _loading = true;
  late Map<int, List<String>> _byMonth;

  @override
  void initState() {
    super.initState();
    // deutsche Monatsnamen initialisieren
    initializeDateFormatting('de', null).then((_) => _loadYearDocs());
  }

  Future<void> _loadYearDocs() async {
    final prefs = await SharedPreferences.getInstance();
    final map = {for (var m = 1; m <= 12; m++) m: <String>[]};

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('docs_')) continue;
      final paths = prefs.getStringList(key) ?? [];
      for (final path in paths) {
        try {
          final file = File(path);
          if (!await file.exists()) continue;
          final dt = await file.lastModified();
          if (dt.year == widget.year) {
            map[dt.month]!.add(path);
          }
        } catch (_) {}
      }
    }

    map.removeWhere((_, v) => v.isEmpty);

    setState(() {
      _byMonth = map;
      _loading = false;
    });
  }

  Future<void> _openDoc(String path) async {
    await OpenFile.open(path);
  }

  Future<void> _downloadDoc(String path) async {
    final destDir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Zielordner wählen',
    );
    if (destDir == null) return;
    final fileName = p.basename(path);
    try {
      await File(path).copy(p.join(destDir, fileName));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Datei gespeichert: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Speichern: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Belege ${widget.year}', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child: Image.asset('assets/Pfeil_Back.png', width: 24, height: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _byMonth.isEmpty
          ? Center(child: Text('Keine Belege für ${widget.year} gefunden.'))
          : ListView(
        children: _byMonth.entries.expand<Widget>((entry) {
          final monthName = DateFormat.MMMM('de')
              .format(DateTime(widget.year, entry.key));
          return [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                monthName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            for (final path in entry.value)
              ListTile(
                leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
                title: Text(p.basename(path)),
                onTap: () => _openDoc(path),
                trailing: IconButton(
                  icon: const Icon(Icons.download, color: Colors.green),
                  splashRadius: 24,
                  onPressed: () => _downloadDoc(path),
                ),
              ),
          ];
        }).toList(),
      ),
    );
  }
}
