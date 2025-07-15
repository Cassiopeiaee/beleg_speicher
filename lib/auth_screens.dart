// lib/auth_screens.dart

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:beleg_speicher/home_page.dart'; // Pfad zur HomePage anpassen

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();

  String _email = '';
  String _password = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // aus secure storage auslesen
    final savedEmail = await _secureStorage.read(key: 'user_email');
    final savedPassword = await _secureStorage.read(key: 'user_password');

    if (savedEmail == null || savedPassword == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein Konto gefunden. Bitte registrieren.')),
      );
      return;
    }
    if (_email != savedEmail || _password != savedPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ungültige Anmeldedaten.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Anmeldung erfolgreich!')),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(
          firstName: 'Vorname',
          lastName: 'Nachname',
        ),
      ),
    );
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
              // E-Mail-Feld
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'E-Mail',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 16),
              // Passwort-Feld
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
                  ),
                ),
                obscureText: true,
                validator: (v) =>
                (v != null && v.length >= 8 && RegExp(r'\d').hasMatch(v))
                    ? null
                    : 'Mindestens 8 Zeichen & eine Zahl',
                onSaved: (v) => _password = v!,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.purple.shade700;
                      }
                      return Colors.purple.shade400;
                    }),
                    overlayColor: MaterialStateProperty.all(
                        Colors.white.withOpacity(0.2)),
                    padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  child: const Text('Einloggen',
                      style: TextStyle(color: Colors.white)),
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
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _secureStorage = const FlutterSecureStorage();

  bool _showPwdHint = false;
  bool _isLengthValid = false;
  bool _hasNumber = false;

  String _email = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(() {
      setState(() {
        _showPwdHint = _passwordFocus.hasFocus;
      });
    });
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final pwd = _passwordController.text;
    setState(() {
      _isLengthValid = pwd.length >= 8;
      _hasNumber = RegExp(r'\d').hasMatch(pwd);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Daten sicher speichern
    await _secureStorage.write(key: 'user_email', value: _email);
    await _secureStorage.write(key: 'user_password', value: _password);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrierung erfolgreich!')),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(
          firstName: 'Vorname',
          lastName: 'Nachname',
        ),
      ),
    );
  }

  Color _bulletColor(bool valid) => valid ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Registrieren', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child:
            Image.asset('assets/Pfeil_Back.png', width: 24, height: 24),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // E-Mail
              TextFormField(
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'E-Mail',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                      BorderSide(color: Colors.purple.shade400, width: 2)),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 16),
              // Passwort mit Bullet-Hinweis
              TextFormField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.black)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide:
                      BorderSide(color: Colors.purple.shade400, width: 2)),
                ),
                obscureText: true,
                validator: (v) => (_isLengthValid && _hasNumber)
                    ? null
                    : 'Passwort entspricht nicht den Anforderungen',
                onSaved: (v) => _password = v!,
              ),

              // Bullet-Points
              if (_showPwdHint) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('• ',
                        style:
                        TextStyle(color: _bulletColor(_isLengthValid))),
                    Expanded(
                      child: Text('Mindestlänge 8 Zeichen',
                          style:
                          TextStyle(color: _bulletColor(_isLengthValid))),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('• ', style: TextStyle(color: _bulletColor(_hasNumber))),
                    Expanded(
                      child: Text('Mindestens 1 Zahl',
                          style: TextStyle(color: _bulletColor(_hasNumber))),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.resolveWith<Color>((states) {
                      if (states.contains(MaterialState.pressed)) {
                        return Colors.purple.shade700;
                      }
                      return Colors.purple.shade400;
                    }),
                    overlayColor: MaterialStateProperty.all(
                        Colors.white.withOpacity(0.2)),
                    padding: MaterialStateProperty.all(const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  child: const Text('Konto erstellen',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
