// lib/ordner_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'inside_ordner.dart';
import 'cloud_sync_manager.dart';

class OrdnerPage extends StatefulWidget {
  const OrdnerPage({Key? key}) : super(key: key);

  @override
  State<OrdnerPage> createState() => _OrdnerPageState();
}

class _OrdnerPageState extends State<OrdnerPage> {
  static const _prefsFoldersKey = 'saved_folders';
  static const _prefsGroupsKey = 'saved_groups';

  bool _isLoading = false;
  List<String> _folders = [];
  Map<String, List<String>> _groups = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1) Lokale Gruppen laden (als Fallback)
      final groupsJson = prefs.getString(_prefsGroupsKey);
      if (groupsJson != null) {
        final decoded = jsonDecode(groupsJson) as Map<String, dynamic>;
        _groups = decoded.map((k, v) => MapEntry(k, List<String>.from(v)));
      }

      if (await CloudSyncManager.isSyncEnabledLocal()) {
        // 2) Gruppen aus Firestore holen (überschreibt lokale)
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          if (doc.exists && doc.data()!['groups'] is Map) {
            final gm = Map<String, dynamic>.from(doc.data()!['groups']);
            _groups = gm.map((k, v) => MapEntry(k, List<String>.from(v as List)));
          }
        }

        // 3) Ordner nur aus Cloud laden
        _folders = await CloudSyncManager.listCloudFolders();
        // *** NEU: herausfiltern, was bereits in einer Gruppe steckt ***
        final grouped = _groups.values.expand((e) => e).toSet();
        _folders = _folders.where((f) => !grouped.contains(f)).toList();

        // in prefs cachen
        await prefs.setStringList(_prefsFoldersKey, _folders);
      } else {
        // 4) Fallback: nur lokal
        final saved = prefs.getStringList(_prefsFoldersKey);
        if (saved != null && saved.isNotEmpty) {
          _folders = List.from(saved);
        } else {
          _folders = ['2025', '2024'];
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsFoldersKey, _folders);
    await prefs.setString(_prefsGroupsKey, jsonEncode(_groups));

    if (await CloudSyncManager.isSyncEnabledLocal()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Speichere in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          // alle Ordner: ungrupped + grouped
          'folders': [
            ..._folders,
            ..._groups.values.expand((e) => e),
          ],
          'groups': _groups,
        }, SetOptions(merge: true));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordner', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptions,
        backgroundColor: Colors.purple.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
        const Text('Hinzufügen', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
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
                        hintText: 'Suche Ordner',
                        hintStyle: TextStyle(color: Colors.black87),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Gruppen + ungruppierte Ordner
                  Expanded(
                    child: ListView(
                      children: [
                        // Gruppen-Bereich
                        for (var entry in _groups.entries)
                          ExpansionTile(
                            title: Text(
                              entry.key,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            iconColor: Colors.black,
                            collapsedIconColor: Colors.black,
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _groups.remove(entry.key));
                                _saveAll();
                              },
                            ),
                            children: [
                              for (var name in entry.value)
                                GestureDetector(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          InsideOrdnerPage(folderName: name),
                                    ),
                                  ),
                                  child: _FolderTile(
                                    name: name,
                                    onRename: () =>
                                        _showFolderDialog(original: name),
                                    onGroup: null,
                                    onRemoveFromGroup: () {
                                      setState(() {
                                        entry.value.remove(name);
                                        _folders.add(name);
                                      });
                                      _saveAll();
                                    },
                                    onDelete: () {
                                      setState(
                                              () => entry.value.remove(name));
                                      _saveAll();
                                    },
                                  ),
                                ),
                            ],
                          ),

                        // Titel „Nicht zugeordnet“
                        if (_folders.isNotEmpty) ...[
                          const Divider(thickness: 2, color: Colors.purple),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'Nicht zugeordnet',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],

                        // Ungruppierte Ordner
                        for (var name in _folders)
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    InsideOrdnerPage(folderName: name),
                              ),
                            ),
                            child: _FolderTile(
                              name: name,
                              onRename: () =>
                                  _showFolderDialog(original: name),
                              onGroup: () => _showAssignGroup(name),
                              onRemoveFromGroup: null,
                              onDelete: () {
                                setState(() => _folders.remove(name));
                                _saveAll();
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lade-Overlay
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

  // BottomSheet: „Gruppe erstellen“ / „Ordner erstellen“
  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.group_add),
            title: const Text('Gruppe erstellen'),
            onTap: () {
              Navigator.of(context).pop();
              _showGroupDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.create_new_folder),
            title: const Text('Ordner erstellen'),
            onTap: () {
              Navigator.of(context).pop();
              _showFolderDialog();
            },
          ),
        ]),
      ),
    );
  }

  // Dialog: neue Gruppe
  void _showGroupDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gruppe erstellen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Gruppen-Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty && !_groups.containsKey(name)) {
                setState(() => _groups[name] = []);
                _saveAll();
              }
              Navigator.of(context).pop();
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  // Dialog: Ordner erstellen / umbenennen
  void _showFolderDialog({String? original}) {
    final isRename = original != null;
    final controller = TextEditingController(text: original ?? '');
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title:
        Text(isRename ? 'Ordner umbenennen' : 'Ordner erstellen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  if (isRename) {
                    if (_folders.contains(original)) {
                      final i = _folders.indexOf(original!);
                      _folders[i] = newName;
                    } else {
                      for (var list in _groups.values) {
                        final idx = list.indexOf(original!);
                        if (idx != -1) list[idx] = newName;
                      }
                    }
                  } else {
                    _folders.insert(0, newName);
                  }
                });
                _saveAll();
              }
              Navigator.of(context).pop();
            },
            child: Text(isRename ? 'Umbenennen' : 'Bestätigen'),
          ),
        ],
      ),
    );
  }

  // BottomSheet: Ordner zu Gruppe hinzufügen
  void _showAssignGroup(String folderName) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (var groupName in _groups.keys)
            ListTile(
              title: Text(groupName),
              onTap: () {
                setState(() {
                  _folders.remove(folderName);
                  _groups[groupName]!.add(folderName);
                });
                _saveAll();
                Navigator.of(context).pop();
              },
            ),
        ]),
      ),
    );
  }
}

/// Einzelne Tile-Komponente
class _FolderTile extends StatelessWidget {
  final String name;
  final VoidCallback onRename;
  final VoidCallback? onGroup;
  final VoidCallback? onRemoveFromGroup;
  final VoidCallback? onDelete;

  const _FolderTile({
    required this.name,
    required this.onRename,
    this.onGroup,
    this.onRemoveFromGroup,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Row(
          children: [
            Image.asset('assets/folder_home.png', width: 32, height: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
            ),
            if (onRemoveFromGroup != null)
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: onRemoveFromGroup,
              ),
            IconButton(
              icon: const Icon(Icons.group, color: Colors.purple),
              onPressed: onGroup,
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.grey),
              onPressed: onRename,
              splashRadius: 24,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.black54),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
