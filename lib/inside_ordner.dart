// lib/inside_ordner.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class InsideOrdnerPage extends StatefulWidget {
  final String folderName;
  const InsideOrdnerPage({super.key, required this.folderName});

  @override
  State<InsideOrdnerPage> createState() => _InsideOrdnerPageState();
}

class _InsideOrdnerPageState extends State<InsideOrdnerPage> {
  static const _prefsDocsPrefix = 'docs_';
  static const _prefsEventsKey = 'calendar_events';
  List<String> _docs = [];

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved =
    prefs.getStringList('$_prefsDocsPrefix${widget.folderName}');
    setState(() {
      _docs = saved ?? [];
    });
  }

  Future<void> _saveDocs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      '$_prefsDocsPrefix${widget.folderName}',
      _docs,
    );
  }

  Future<void> _addCalendarEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsEventsKey);
    final Map<String, dynamic> decoded =
    raw != null ? jsonDecode(raw) as Map<String, dynamic> : {};
    final events =
    decoded.map((k, v) => MapEntry(k, List<String>.from(v)));
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    events[today] = (events[today] ?? []);
    if (!events[today]!.contains(widget.folderName)) {
      events[today]!.add(widget.folderName);
    }
    await prefs.setString(_prefsEventsKey, jsonEncode(events));
  }

  Future<void> _importImage() async {
    final picker = ImagePicker();
    final XFile? image =
    await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _docs.insert(0, image.path));
      await _saveDocs();
      await _addCalendarEvent();
    }
  }

  Future<void> _importFile() async {
    final typeGroup =
    XTypeGroup(label: 'Alle Dateien', extensions: ['*']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() => _docs.insert(0, file.path));
      await _saveDocs();
      await _addCalendarEvent();
    }
  }

  Future<void> _renameDoc(int index) async {
    final oldPath = _docs[index];
    final oldName = File(oldPath).uri.pathSegments.last;
    final controller = TextEditingController(text: oldName);

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dokument umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: 'Neuer Name',
            labelStyle: const TextStyle(color: Colors.black),
            border: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide:
              BorderSide(color: Colors.purple.shade400, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final dir = File(oldPath).parent.path;
                final newPath = '$dir/$newName';
                await File(oldPath).rename(newPath);
                setState(() => _docs[index] = newPath);
                await _saveDocs();
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade400,
            ),
            child: const Text('Umbenennen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        Text(widget.folderName, style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImportOptions,
        backgroundColor: Colors.purple.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Hinzufügen',
            style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: _docs.isEmpty
            ? const Center(child: Text('Keine Dokumente'))
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final path = _docs[index];
            final name = File(path).uri.pathSegments.last;
            return ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              leading:
              const Icon(Icons.insert_drive_file, color: Colors.blue),
              title:
              Text(name, style: const TextStyle(color: Colors.black)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Datei öffnen
                  IconButton(
                    icon:
                    const Icon(Icons.visibility, color: Colors.purple),
                    onPressed: () => OpenFile.open(path),
                  ),
                  // Datei teilen / herunterladen
                  IconButton(
                    icon:
                    const Icon(Icons.download, color: Colors.green),
                    onPressed: () => Share.shareXFiles([XFile(path)]),
                  ),
                  // Datei umbenennen
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.grey),
                    onPressed: () => _renameDoc(index),
                  ),
                  // Löschen
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _docs.removeAt(index);
                      });
                      _saveDocs();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showImportOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Importieren aus Galerie'),
            onTap: () {
              Navigator.of(context).pop();
              _importImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Importieren aus Dokumente'),
            onTap: () {
              Navigator.of(context).pop();
              _importFile();
            },
          ),
        ]),
      ),
    );
  }
}
