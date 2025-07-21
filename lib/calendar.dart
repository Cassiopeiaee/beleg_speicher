// lib/calendar.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';    // ← Import
import 'package:beleg_speicher/inside_ordner.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const _prefsEventsKey = 'calendar_events';
  Map<DateTime, List<String>> _events = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _localeInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeLocaleAndLoad();
  }

  Future<void> _initializeLocaleAndLoad() async {
    // Lokale Datumssymbole für Deutsch initialisieren
    await initializeDateFormatting('de', null);
    setState(() => _localeInitialized = true);
    // Events laden
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsEventsKey);
    if (raw != null) {
      final Map<String, dynamic> decoded =
      jsonDecode(raw) as Map<String, dynamic>;
      decoded.forEach((key, list) {
        final date = DateTime.parse(key);
        _events[DateTime(date.year, date.month, date.day)] =
        List<String>.from(list);
      });
    }
    setState(() {});
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selected, DateTime focused) {
    setState(() {
      _selectedDay = DateTime(selected.year, selected.month, selected.day);
      _focusedDay = focused;
    });
  }

  Widget _buildEventList() {
    if (!_localeInitialized || _selectedDay == null) return const SizedBox.shrink();

    final day = _selectedDay!;
    final events = _getEventsForDay(day);
    if (events.isEmpty) return const SizedBox.shrink();

    final label = DateFormat.yMMMMd('de').format(day);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        child: ExpansionTile(
          title: Text('Uploads am $label'),
          children: events.map((folderName) {
            return ListTile(
              title: Text(folderName),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => InsideOrdnerPage(folderName: folderName),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_localeInitialized) {
      // Noch keine Locale → Lade-Bildschirm
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
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TableCalendar<String>(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(_selectedDay, day),
                eventLoader: _getEventsForDay,
                onDaySelected: _onDaySelected,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
            // Drop-down Liste der Dateien für den gewählten Tag
            if (_selectedDay != null) _buildEventList(),
          ],
        ),
      ),
    );
  }
}
