// lib/year_beleg.dart

import 'package:flutter/material.dart';

class YearBelegPage extends StatelessWidget {
  final int year;
  const YearBelegPage({super.key, required this.year});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$year Belege', style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      body: const Center(
        child: Text(
          'Hier erscheinen alle Belege des Jahres.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
