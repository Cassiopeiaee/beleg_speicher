import 'package:flutter/material.dart';
import 'package:beleg_speicher/LandingPage.dart'; // LandingPage für Logout

class HomePage extends StatelessWidget {
  final String firstName;
  final String lastName;

  const HomePage({
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
        onPressed: () {
          // TODO: Hinzufügen-Action
        },
        backgroundColor: Colors.purple.shade400,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Hinzufügen',
            style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Search Bar
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

              // Year Buttons (horizontal scroll)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    10,
                        (index) {
                      final year = DateTime.now().year - index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: _YearButton(year: year),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(height: 2, color: Colors.purple.shade400),

              const SizedBox(height: 16),

              // Feature List
              _FeatureItem(
                icon: Icons.calendar_today,
                title: 'Kalender',
                subtitle: 'Einsehen von Belegen anhand des Datum',
              ),
              Container(height: 1, color: Colors.purple.shade400),
              _FeatureItem(
                icon: Icons.folder,
                title: 'Ordner',
                subtitle: 'Einsehen von Belegen in einem Ordner',
              ),
              Container(height: 1, color: Colors.purple.shade400),
              _FeatureItem(
                icon: Icons.history,
                title: 'Zuletzt geöffnet',
                subtitle: 'Einsehen des zuletzt geöffneten Beleg',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearButton extends StatelessWidget {
  final int year;
  const _YearButton({required this.year});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        padding:
        const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      ),
      child: Text(
        '$year',
        style: const TextStyle(color: Colors.black),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 32, color: Colors.purple.shade400),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.black.withOpacity(0.8)),
      ),
    );
  }
}
