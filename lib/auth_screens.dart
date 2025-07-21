// lib/auth_screens.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:beleg_speicher/home_page.dart';
import 'package:beleg_speicher/reset_password.dart';  // hier liegt ResetPasswordPage
import 'auth_helpers.dart';

/// Gemeinsame Input-Dekoration für alle Textfelder
InputDecoration _buildInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.black),
    border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(color: Colors.purple.shade400, width: 2),
    ),
  );
}

/// Roter Google-Button mit Icon und Text in voller Breite
class GoogleAuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const GoogleAuthButton({
    super.key,
    required this.text,
    required this.onPressed,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Image.asset('assets/google_logo.png', width: 24, height: 24),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '', _password = '';

  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);
      _navigateToHome(cred.user!);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login fehlgeschlagen: ${e.message}')));
    }
  }

  Future<void> _googleLogin() async {
    try {
      final cred = await AuthHelpers.signInWithGoogle();
      final userDoc = FirebaseFirestore.instance.collection('users').doc(cred.user!.uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        await userDoc.set({
          'email': cred.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        });
      }
      _navigateToHome(cred.user!);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google Sign-In fehlgeschlagen: ${e.message}')));
    }
  }

  void _navigateToHome(User user) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(firstName: user.email ?? '', lastName: ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anmelden', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child: Image.asset('assets/Pfeil_Back.png', width: 24, height: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  decoration: _buildInputDecoration('E-Mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                  onSaved: (v) => _email = v!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: _buildInputDecoration('Passwort'),
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
                    onPressed: _emailLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Einloggen',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                    ),
                    child: const Text(
                      'Passwort vergessen?',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blue,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Row(children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('oder'),
              ),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 24),
            GoogleAuthButton(
              text: 'Mit Google anmelden',
              onPressed: _googleLogin,
            ),
          ],
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
  String _email = '', _password = '';
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _showPwdHint = false, _isLengthValid = false, _hasNumber = false;

  @override
  void initState() {
    super.initState();
    _passwordFocus.addListener(() => setState(() => _showPwdHint = _passwordFocus.hasFocus));
    _passwordController.addListener(() {
      final pwd = _passwordController.text;
      setState(() {
        _isLengthValid = pwd.length >= 8;
        _hasNumber = RegExp(r'\d').hasMatch(pwd);
      });
    });
  }
  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _emailRegister() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email, password: _password);
      final uid = cred.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _email,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': 'password',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrierung erfolgreich!')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(firstName: _email, lastName: '')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrierung fehlgeschlagen: ${e.message}')),
      );
    }
  }

  Future<void> _googleRegister() async {
    try {
      final cred = await AuthHelpers.signInWithGoogle();
      final userDoc = FirebaseFirestore.instance.collection('users').doc(cred.user!.uid);
      final snapshot = await userDoc.get();
      if (!snapshot.exists) {
        await userDoc.set({
          'email': cred.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'google',
        });
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) =>
            HomePage(firstName: cred.user!.email ?? '', lastName: '')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-Up fehlgeschlagen: ${e.message}')),
      );
    }
  }

  Color _bulletColor(bool valid) => valid ? Colors.green : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrieren', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child: Image.asset('assets/Pfeil_Back.png', width: 24, height: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  decoration: _buildInputDecoration('E-Mail'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                  (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                  onSaved: (v) => _email = v!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  decoration: _buildInputDecoration('Passwort'),
                  obscureText: true,
                  validator: (v) =>
                  (_isLengthValid && _hasNumber) ? null : 'Mindestens 8 Zeichen & eine Zahl',
                  onSaved: (v) => _password = v!,
                ),
                if (_showPwdHint) ...[
                  const SizedBox(height: 8),
                  Row(children: [
                    Text('• ', style: TextStyle(color: _bulletColor(_isLengthValid))),
                    Expanded(child: Text('Mindestlänge 8 Zeichen',
                        style: TextStyle(color: _bulletColor(_isLengthValid)))),
                  ]),
                  Row(children: [
                    Text('• ', style: TextStyle(color: _bulletColor(_hasNumber))),
                    Expanded(child: Text('Mindestens 1 Zahl',
                        style: TextStyle(color: _bulletColor(_hasNumber)))),
                  ]),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _emailRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Konto erstellen',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 24),
            Row(children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('oder'),
              ),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 24),
            GoogleAuthButton(
              text: 'Mit Google registrieren',
              onPressed: _googleRegister,
            ),
          ],
        ),
      ),
    );
  }
}
