// lib/inside_ordner.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart'; // für compute()
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_sync_manager.dart';

/// Lädt im Hintergrund alle Dateien in einen Ordner.
/// Wird via compute() aufgerufen.
Future<void> _copyFilesInBackground(Map<String, dynamic> args) async {
  final List<String> paths = List<String>.from(args['paths'] as List);
  final String destPath = args['dest'] as String;

  for (final path in paths) {
    final name = p.basename(path);
    try {
      await File(path).copy(p.join(destPath, name));
    } catch (_) {
      // Fehler einzelner Dateien ignorieren
    }
  }
}

class InsideOrdnerPage extends StatefulWidget {
  final String folderName;
  const InsideOrdnerPage({Key? key, required this.folderName})
      : super(key: key);

  @override
  State<InsideOrdnerPage> createState() => _InsideOrdnerPageState();
}

class _InsideOrdnerPageState extends State<InsideOrdnerPage> {
  static const _prefsDocsPrefix = 'docs_';
  static const _prefsEventsKey = 'calendar_events';
  static const _prefsLastOpened = 'last_opened_doc';
  static const _prefsCloudKey = 'cloudSyncEnabled';

  bool _isLoading = false;
  List<String> _docs = [];
  String? _lastOpened;

  @override
  void initState() {
    super.initState();
    _loadLastOpened();
    _loadDocs();
  }

  Future<void> _loadLastOpened() async {
    final prefs = await SharedPreferences.getInstance();
    _lastOpened = prefs.getString(_prefsLastOpened);
    setState(() {});
  }

  Future<void> _loadDocs() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefsDocsPrefix${widget.folderName}';

      // Lokale Dokumente
      _docs = prefs.getStringList(key) ?? [];

      // Falls Cloud-Sync aktiv und noch keine lokalen Docs, aus Cloud laden
      if (await CloudSyncManager.isSyncEnabledLocal() && _docs.isEmpty) {
        await CloudSyncManager.downloadFolderToLocal(widget.folderName);
        _docs = prefs.getStringList(key) ?? [];
      }

      setState(() {});
    } finally {
      setState(() => _isLoading = false);
    }
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
    final events = decoded.map((k, v) => MapEntry(k, List<String>.from(v)));
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    events[today] = (events[today] ?? []);
    if (!events[today]!.contains(widget.folderName)) {
      events[today]!.add(widget.folderName);
    }
    await prefs.setString(_prefsEventsKey, jsonEncode(events));
  }

  Future<void> _maybeUploadToCloud(String localPath) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsCloudKey) != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final file = File(localPath);
    if (!await file.exists()) return;

    final fileName = p.basename(localPath);
    final storageRef =
    FirebaseStorage.instance.ref('backups/$uid/${widget.folderName}/$fileName');
    final filesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('files');

    try {
      // Nur uploaden, wenn nicht vorhanden
      final meta = await storageRef.getMetadata().catchError((_) => null);
      if (meta == null) {
        await storageRef.putFile(file);
        await filesCol.doc('${widget.folderName}/$fileName').set({
          'folder': widget.folderName,
          'fileName': fileName,
          'uploadedAt': FieldValue.serverTimestamp(),
          'storagePath': storageRef.fullPath,
        });
        debugPrint('Cloud-Upload $localPath erfolgreich');
      }
    } catch (e) {
      debugPrint('Cloud-Upload $localPath fehlgeschlagen: $e');
    }
  }

  Future<void> _importImage() async {
    setState(() => _isLoading = true);
    try {
      final picker = ImagePicker();
      final XFile? image =
      await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        _docs.insert(0, image.path);
        await _saveDocs();
        await _addCalendarEvent();
        await _maybeUploadToCloud(image.path);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _importFile() async {
    setState(() => _isLoading = true);
    try {
      final typeGroup = XTypeGroup(label: 'Alle Dateien', extensions: ['*']);
      final file = await openFile(acceptedTypeGroups: [typeGroup]);
      if (file != null) {
        _docs.insert(0, file.path);
        await _saveDocs();
        await _addCalendarEvent();
        await _maybeUploadToCloud(file.path);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _renameDoc(int index) async {
    final oldPath = _docs[index];
    final oldName = p.basename(oldPath);
    final controller = TextEditingController(text: oldName);

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dokument umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Neuer Name',
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
                setState(() => _isLoading = true);
                try {
                  final dir = File(oldPath).parent.path;
                  final newPath = p.join(dir, newName);
                  await File(oldPath).rename(newPath);
                  _docs[index] = newPath;
                  await _saveDocs();
                  await _addCalendarEvent();
                  await _maybeUploadToCloud(newPath);
                } finally {
                  setState(() => _isLoading = false);
                }
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400),
            child: const Text('Umbenennen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAllDocs() async {
    setState(() => _isLoading = true);
    try {
      final destPath = await FilePicker.platform
          .getDirectoryPath(dialogTitle: 'Zielordner auswählen');
      if (destPath != null) {
        await compute(_copyFilesInBackground, {
          'paths': _docs,
          'dest': destPath,
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alle Dokumente exportiert')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Fehler beim Export: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showImportOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
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

  Future<void> _openDoc(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsLastOpened, path);
    _lastOpened = path;
    await _addCalendarEvent();
    await OpenFile.open(path);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName,
            style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _exportAllDocs,
              icon: const Icon(Icons.folder_zip, size: 20),
              label: const Text('Exportieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showImportOptions,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Hinzufügen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ]),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _docs.isEmpty
                ? const Center(child: Text('Keine Dokumente'))
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _docs.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final path = _docs[index];
                final name = p.basename(path);
                final isLast = path == _lastOpened;
                return ListTile(
                  tileColor: isLast
                      ? Colors.yellow.shade100
                      : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  leading: const Icon(Icons.insert_drive_file,
                      color: Colors.blue),
                  title:
                  Text(name, style: const TextStyle(color: Colors.black)),
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.visibility,
                                color: Colors.purple),
                            onPressed: () => _openDoc(path)),
                        IconButton(
                            icon: const Icon(Icons.download,
                                color: Colors.green),
                            onPressed: () =>
                                Share.shareXFiles([XFile(path)])),
                        IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.grey),
                            onPressed: () => _renameDoc(index)),
                        IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red),
                            onPressed: () {
                              _docs.removeAt(index);
                              _saveDocs();
                              setState(() {});
                            }),
                      ]),
                );
              },
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
