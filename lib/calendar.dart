// lib/calendar.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'inside_ordner.dart';

// Notification-Pakete
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const _prefsEventsKey   = 'calendar_events';
  static const _prefsNotesKey    = 'calendar_notes';
  static const _prefsFoldersKey  = 'saved_folders';
  static const _prefsGroupsKey   = 'saved_groups';

  final FlutterLocalNotificationsPlugin _notifications =
  FlutterLocalNotificationsPlugin();

  Map<DateTime, List<String>> _uploadEvents = {};
  final Map<DateTime, List<String>> _notes        = {};
  DateTime _focusedDay    = DateTime.now();
  DateTime? _selectedDay;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocaleAndLoad();
    _initializeNotifications();
  }

  Future<void> _initializeLocaleAndLoad() async {
    await initializeDateFormatting('de', null);
    setState(() => _localeInitialized = true);
    await _loadUploadEvents();
    await _loadNotes();
  }

  Future<void> _initializeNotifications() async {
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();
    const linux   = LinuxInitializationSettings(defaultActionName: 'Öffnen');
    await _notifications.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
        linux: linux,
      ),
    );
  }

  Future<void> _loadUploadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFolders = prefs.getStringList(_prefsFoldersKey) ?? [];
    final groupsRaw    = prefs.getString(_prefsGroupsKey);
    final Map<String, List<String>> groups = {};
    if (groupsRaw != null) {
      (jsonDecode(groupsRaw) as Map<String, dynamic>)
          .forEach((k, v) => groups[k] = List<String>.from(v));
    }
    final active = {...savedFolders, for (var g in groups.values) ...g};

    final raw = prefs.getString(_prefsEventsKey);
    final Map<DateTime, List<String>> filtered = {};
    if (raw != null) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((dateStr, items) {
        final d = DateTime.parse(dateStr);
        final key = DateTime(d.year, d.month, d.day);
        final kept = (items as List<dynamic>).cast<String>()
            .where(active.contains)
            .toList();
        if (kept.isNotEmpty) filtered[key] = kept;
      });
    }
    setState(() => _uploadEvents = filtered);
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsNotesKey);
    if (raw != null) {
      (jsonDecode(raw) as Map<String, dynamic>).forEach((k, v) {
        final d = DateTime.parse(k);
        _notes[DateTime(d.year, d.month, d.day)] =
            (v as List<dynamic>).cast<String>();
      });
    }
    setState(() {});
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final toSave = <String, List<String>>{};
    _notes.forEach((k, v) => toSave[k.toIso8601String()] = v);
    await prefs.setString(_prefsNotesKey, jsonEncode(toSave));
  }

  List<String> _getUploadsForDay(DateTime day) =>
      _uploadEvents[DateTime(day.year, day.month, day.day)] ?? [];

  List<String> _getNotesForDay(DateTime day) =>
      _notes[DateTime(day.year, day.month, day.day)] ?? [];

  bool _hasNoteForDay(DateTime day) =>
      _notes.containsKey(DateTime(day.year, day.month, day.day));

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = DateTime(selected.year, selected.month, selected.day);
      _focusedDay  = focused;
    });
  }

  Future<void> _scheduleNotification(DateTime date, String body) async {
    final tzDate = tz.TZDateTime.from(date, tz.local);
    await _notifications.zonedSchedule(
      date.hashCode,
      'Erinnerung',
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Erinnerungen',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
      // v13.x:
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> _showNoteDialog({int? editIndex}) async {
    if (_selectedDay == null) return;
    final key = _selectedDay!;
    final ctrl = TextEditingController(
      text: editIndex != null ? _notes[key]![editIndex] : '',
    );

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(editIndex != null
            ? 'Notiz bearbeiten'
            : 'Notiz für ${DateFormat.yMMMd('de').format(key)}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Schreibe deine Notiz…',
              enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black)),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.purple)),
            ),
          ),
          const SizedBox(height: 12),
          if (editIndex == null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () async {
                final text = ctrl.text.trim();
                if (text.isNotEmpty) {
                  await _scheduleNotification(key, text);
                }
                Navigator.of(ctx).pop();
              },
              child: const Text('Benachrichtigung planen'),
            ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade400),
            onPressed: () {
              final text = ctrl.text.trim();
              if (text.isNotEmpty) {
                final list = _notes.putIfAbsent(key, () => []);
                if (editIndex != null) {
                  list[editIndex] = text;
                } else {
                  list.add(text);
                }
                _saveNotes();
              }
              setState(() {});
              Navigator.of(ctx).pop();
            },
            child: Text(editIndex != null ? 'Aktualisieren' : 'Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNoteAt(int index) async {
    if (_selectedDay == null) return;
    final key = _selectedDay!;
    final list = _notes[key]!;
    list.removeAt(index);
    if (list.isEmpty) _notes.remove(key);
    await _saveNotes();
    setState(() {});
  }

  Widget _buildUploadList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final day = _selectedDay!;
    final uploads = _getUploadsForDay(day);
    if (uploads.isEmpty) return const SizedBox.shrink();
    final label = DateFormat.yMMMMd('de').format(day);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          title: Text('Uploads am $label'),
          children: uploads.map((folderName) {
            return ListTile(
              title: Text(folderName),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      InsideOrdnerPage(folderName: folderName),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNoteList() {
    if (_selectedDay == null) return const SizedBox.shrink();
    final day = _selectedDay!;
    final notes = _getNotesForDay(day);
    if (notes.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        color: Colors.yellow.shade50,
        elevation: 2,
        child: ExpansionTile(
          title: const Text('Notizen'),
          children: List.generate(notes.length, (i) {
            return ListTile(
              title: Text(notes[i]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showNoteDialog(editIndex: i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteNoteAt(i),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          splashRadius: 24,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Kalender
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TableCalendar(
                firstDay: DateTime(2000),
                lastDay:  DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) =>
                _selectedDay != null && isSameDay(_selectedDay, d),
                onDaySelected: _onDaySelected,
                eventLoader: _getUploadsForDay,
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, _) {
                    final key = DateTime(day.year, day.month, day.day);
                    if (_hasNoteForDay(day)) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.yellow.shade300,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${day.day}',
                          style: const TextStyle(color: Colors.black),
                        ),
                      );
                    }
                    return null;
                  },
                  markerBuilder: (ctx, day, events) {
                    if (events.isNotEmpty) {
                      return Positioned(
                        bottom: 4,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.pink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                calendarStyle: const CalendarStyle(
                  todayDecoration:    BoxDecoration(color: Colors.purple, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered:      true,
                ),
              ),
            ),

            // Uploads
            if (_selectedDay != null) _buildUploadList(),

            // Button „Notiz hinzufügen“
            if (_selectedDay != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ElevatedButton(
                  onPressed: () => _showNoteDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow.shade700,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Notiz hinzufügen'),
                ),
              ),

            // Notizen
            if (_selectedDay != null) _buildNoteList(),
          ],
        ),
      ),
    );
  }
}
