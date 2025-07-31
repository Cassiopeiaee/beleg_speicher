// lib/cloud_sync_manager.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Verwaltet Cloud-Sync mithilfe der Firebase-UID als Schlüssel
class CloudSyncManager {
  static const _prefsKey = 'cloudSyncEnabled';

  /// Lokaler Flag (für schnellen UI-Start)
  static Future<bool> isSyncEnabledLocal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? false;
  }

  /// Remote-Flag aus Firestore laden.
  /// Legt bei fehlendem Doc automatisch cloudSyncEnabled=true an.
  static Future<bool> fetchRemoteSyncFlag() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    final snap = await docRef.get();
    if (!snap.exists) {
      // Erstinitialisierung: direkt aktivieren
      await setRemoteSyncFlag(true);
      return true;
    }
    final enabled = snap.data()?['cloudSyncEnabled'] as bool? ?? false;
    // lokal cachen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
    return enabled;
  }

  /// Remote-Flag in Firestore setzen *und* lokal cachen
  static Future<void> setRemoteSyncFlag(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await docRef.set(
      {'cloudSyncEnabled': enabled},
      SetOptions(merge: true),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);
  }

  /// Listet alle Ordner (Prefix) unter backups/{uid}/ in Firebase Storage
  static Future<List<String>> listCloudFolders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final uid = user.uid;
    final res = await FirebaseStorage.instance
        .ref('backups/$uid')
        .listAll();
    return res.prefixes.map((p) => p.name).toList();
  }

  /// Listet alle Dateien in einem Cloud-Ordner backups/{uid}/{folder}/
  /// und gibt hierzu die Download-URLs zurück.
  static Future<List<String>> listFilesInCloud(String folder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];
    final uid = user.uid;
    final res = await FirebaseStorage.instance
        .ref('backups/$uid/$folder')
        .listAll();
    final urls = <String>[];
    for (final item in res.items) {
      final url = await item.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  /// Uploadt alle lokal existierenden Dokumente in die Cloud
  static Future<void> uploadLocalToCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final storage = FirebaseStorage.instance;
    final filesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('files');

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('docs_')) continue;
      final folder = key.substring('docs_'.length);
      final paths = prefs.getStringList(key) ?? [];
      for (final path in paths) {
        final file = File(path);
        if (!await file.exists()) continue;
        final name = path.split(Platform.pathSeparator).last;
        final ref = storage.ref('backups/$uid/$folder/$name');
        try {
          await ref.putFile(file);
          await filesCol.doc('$folder/$name').set({
            'folder': folder,
            'fileName': name,
            'storagePath': ref.fullPath,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          debugPrint('Upload $path erfolgreich');
        } catch (e) {
          debugPrint('Upload $path fehlgeschlagen: $e');
        }
      }
    }
  }

  /// Downloadt alle in der Cloud gespeicherten Dateien herunter
  /// und legt sie lokal ab
  static Future<void> downloadCloudToLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    final filesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('files');
    final storage = FirebaseStorage.instance;
    final localRoot = await getApplicationDocumentsDirectory();

    final snapshot = await filesCol.get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final folder = data['folder'] as String;
      final name = data['fileName'] as String;
      final storagePath = data['storagePath'] as String;

      final dir = Directory('${localRoot.path}/$folder');
      if (!await dir.exists()) await dir.create(recursive: true);

      final file = File('${dir.path}/$name');
      try {
        final bytes = await storage.ref(storagePath).getData();
        if (bytes != null) {
          await file.writeAsBytes(bytes, flush: true);
          final key = 'docs_$folder';
          final list = prefs.getStringList(key) ?? [];
          if (!list.contains(file.path)) {
            list.add(file.path);
            await prefs.setStringList(key, list);
          }
          debugPrint('Download $storagePath → ${file.path} erfolgreich');
        }
      } catch (e) {
        debugPrint('Download $storagePath fehlgeschlagen: $e');
      }
    }
  }
}
