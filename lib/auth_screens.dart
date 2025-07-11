import 'package:flutter/material.dart';

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
      // TODO: Login-Logik hier
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anmeldung…')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child: Image.asset(
              'assets/Pfeil_Back.png',
              width: 24,
              height: 24,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
          splashColor: Colors.purple.shade700.withOpacity(0.2),
          hoverColor: Colors.purple.shade600.withOpacity(0.1),
        ),
        title: const Text('Anmelden'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-Mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Passwort'),
                obscureText: true,
                validator: (v) =>
                (v != null && v.length >= 6) ? null : 'Mind. 6 Zeichen',
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
                      Colors.white.withOpacity(0.2),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: const Text('Einloggen'),
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
      // TODO: Registrierungs-Logik hier
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrierung…')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child: Image.asset(
              'assets/Pfeil_Back.png',
              width: 24,
              height: 24,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
          splashColor: Colors.purple.shade700.withOpacity(0.2),
          hoverColor: Colors.purple.shade600.withOpacity(0.1),
        ),
        title: const Text('Registrieren'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-Mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Passwort'),
                obscureText: true,
                validator: (v) =>
                (v != null && v.length >= 6) ? null : 'Mind. 6 Zeichen',
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
                      Colors.white.withOpacity(0.2),
                    ),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 22),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: const Text('Konto erstellen'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
