import 'package:flutter/material.dart';
import 'package:beleg_speicher/home_page.dart'; // Pfad zu deiner HomePage

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Deine Login-Logik hier
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anmeldung…')),
      );
      // Nach erfolgreicher Anmeldung zur HomePage wechseln:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(               // kein const hier
            firstName: 'Vorname',
            lastName: 'Nachname',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anmelden', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child: Image.asset('assets/Pfeil_Back.png', width: 24, height: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
          splashColor: Colors.purple.shade700.withOpacity(0.2),
          hoverColor: Colors.purple.shade600.withOpacity(0.1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'E-Mail',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                  ),
                ),
                obscureText: true,
                validator: (v) => (v != null && v.length >= 6) ? null : 'Mindestens 6 Zeichen',
                onSaved: (v) => _password = v!,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.purple.shade700;
                      }
                      return Colors.purple.shade400;
                    }),
                    overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.2)),
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  child: const Text('Einloggen', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  void _submit() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // TODO: Deine Registrierungs-Logik hier
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrierung…')),
      );
      // Nach erfolgreicher Registrierung zur HomePage wechseln:
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(             // kein const hier
            firstName: 'Vorname',
            lastName: 'Nachname',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrieren', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child: Image.asset('assets/Pfeil_Back.png', width: 24, height: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
          splashColor: Colors.purple.shade700.withOpacity(0.2),
          hoverColor: Colors.purple.shade600.withOpacity(0.1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'E-Mail',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                  ),
                ),
                obscureText: true,
                validator: (v) => (v != null && v.length >= 6) ? null : 'Mindestens 6 Zeichen',
                onSaved: (v) => _password = v!,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.purple.shade700;
                      }
                      return Colors.purple.shade400;
                    }),
                    overlayColor: MaterialStateProperty.all(Colors.white.withOpacity(0.2)),
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  child: const Text('Konto erstellen', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
