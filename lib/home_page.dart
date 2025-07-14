import 'package:flutter/material.dart';
import 'package:beleg_speicher/LandingPage.dart';

class HomePage extends StatelessWidget {
  final String firstName;
  final String lastName;

  // Jahresliste als final-Feld, wird zur Laufzeit erzeugt
  final List<int> _years = List<int>.generate(
    10,
        (index) => DateTime.now().year - index,
  );

  // Hier kein `const` mehr:
  HomePage({
    super.key,
    required this.firstName,
    required this.lastName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            splashRadius: 24,
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LandingPage()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () { /* TODO: Hinzufügen-Action */ },
        backgroundColor: Colors.purple.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Hinzufügen', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Herzlich Willkommen',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.black),
            ),
            Text(
              '$firstName $lastName',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 2,
              color: Colors.purple.shade400,
              margin: const EdgeInsets.only(bottom: 16),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(Icons.search, color: Colors.purple),
                  hintText: 'Suche',
                  hintStyle: TextStyle(color: Colors.black87),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _years.map((year) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _YearPillButton(year: year),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(height: 2, color: Colors.purple.shade400),
            const SizedBox(height: 16),
            _PillButton(
              assetPath: 'assets/calendar_home.png',
              title: 'Kalender',
              subtitle: 'Einsehen von Belegen anhand des Datum',
            ),
            const SizedBox(height: 12),
            _PillButton(
              assetPath: 'assets/folder_home.png',
              title: 'Ordner',
              subtitle: 'Einsehen von Belegen in einem Ordner',
            ),
            const SizedBox(height: 12),
            _PillButton(
              assetPath: 'assets/time_home.png',
              title: 'Zuletzt geöffnet',
              subtitle: 'Einsehen des zuletzt geöffneten Beleg',
            ),
          ],
        ),
      ),
    );
  }
}

class _YearPillButton extends StatelessWidget {
  final int year;
  const _YearPillButton({required this.year});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            '$year',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String assetPath;
  final String title;
  final String subtitle;
  const _PillButton({
    required this.assetPath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              Image.asset(assetPath, width: 32, height: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
