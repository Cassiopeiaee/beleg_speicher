// lib/inside_ordner.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:beleg_speicher/LandingPage.dart';

class InsideOrdnerPage extends StatefulWidget {
  final String folderName;
  const InsideOrdnerPage({super.key, required this.folderName});

  @override
  State<InsideOrdnerPage> createState() => _InsideOrdnerPageState();
}

class _InsideOrdnerPageState extends State<InsideOrdnerPage> {
  static const _prefsDocsPrefix = 'docs_';
  List<String> _docs = [];

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  Future<void> _loadDocs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('$_prefsDocsPrefix${widget.folderName}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName, style: const TextStyle(color: Colors.black)),
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
        label: const Text('Hinzufügen', style: TextStyle(color: Colors.white)),
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
              leading: const Icon(Icons.insert_drive_file, color: Colors.blue),
              title: Text(name, style: const TextStyle(color: Colors.black)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.purple),
                    onPressed: () {
                      // TODO: Viewer für Datei öffnen
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Colors.green),
                    onPressed: () {
                      // TODO: Datei herunterladen / teilen
                    },
                  ),
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
            onTap: () async {
              Navigator.of(context).pop();
              final picker = ImagePicker();
              final XFile? image =
              await picker.pickImage(source: ImageSource.gallery);
              if (image != null) {
                setState(() => _docs.insert(0, image.path));
                await _saveDocs();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Importieren aus Dokumente'),
            onTap: () async {
              Navigator.of(context).pop();
              // Mit file_selector:
              final typeGroup = XTypeGroup(label: 'Alle Dateien', extensions: ['*']);
              final file = await openFile(acceptedTypeGroups: [typeGroup]);
              if (file != null) {
                setState(() => _docs.insert(0, file.path));
                await _saveDocs();
              }
            },
          ),
        ]),
      ),
    );
  }
}
