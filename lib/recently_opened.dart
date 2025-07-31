// lib/recently_opened.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:beleg_speicher/inside_ordner.dart';

class RecentlyOpenedPage extends StatelessWidget {
  const RecentlyOpenedPage({super.key});

  Future<Map<String, List<String>>> _loadOpenedDocs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('opened_docs') ?? '{}';
    final Map<String, dynamic> decoded = jsonDecode(raw);
    return decoded.map((day, list) => MapEntry(day, List<String>.from(list)));
  }

  String _dayLabel(String dateKey) {
    final today = DateTime.now();
    final d = DateTime.parse(dateKey);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Gestern';
    return '$diff Tage her';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Zuletzt geöffnet', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: FutureBuilder<Map<String, List<String>>>(
        future: _loadOpenedDocs(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!;
          // nur letzte 7 Tage
          final cutoff = DateTime.now().subtract(const Duration(days: 7));
          final recentKeys = data.keys
              .where((k) => DateTime.parse(k).isAfter(cutoff))
              .toList()
            ..sort((a, b) => b.compareTo(a)); // neueste zuerst
          if (recentKeys.isEmpty) {
            return const Center(
                child: Text('Keine Einträge der letzten 7 Tage'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recentKeys.length,
            itemBuilder: (ctx, i) {
              final day = recentKeys[i];
              final label = _dayLabel(day);
              final docs = data[day]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...docs.map((path) {
                    final name = File(path).uri.pathSegments.last;
                    final folderName =
                        File(path).parent.uri.pathSegments.last;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading:
                      const Icon(Icons.insert_drive_file, color: Colors.purple),
                      title: Text(name),
                      subtitle: Text('Ordner: $folderName'),
                      onTap: () {
                        // 1) aufs Dokument direkt öffnen:
                        OpenFile.open(path);
                        // 2) in den Ordner navigieren:
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              InsideOrdnerPage(folderName: folderName),
                        ));
                      },
                    );
                  }),
                  const Divider(thickness: 2, color: Colors.purple),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
