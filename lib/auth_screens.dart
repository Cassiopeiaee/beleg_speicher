// lib/auth_screens.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:beleg_speicher/home_page.dart';
import 'package:beleg_speicher/reset_password.dart';  // hier liegt ResetPasswordPage
import 'auth_helpers.dart';
import 'cloud_sync_manager.dart';

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
  bool _isLoading = false;

  /// Lege in Firestore unter users/{uid} ein Profil an, falls noch nicht vorhanden.
  Future<void> _ensureUserDoc(User user, String provider) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': provider,
      });
    }
  }

  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: _email, password: _password);

      await _ensureUserDoc(cred.user!, 'password');

      // Nur noch Flag hol­en, kein Download mehr:
      await CloudSyncManager.fetchRemoteSyncFlag();

      _navigateToHome(cred.user!);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login fehlgeschlagen: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      final cred = await AuthHelpers.signInWithGoogle() as UserCredential;
      final user = cred.user!;
      await _ensureUserDoc(user, 'google');

      // Nur noch Flag hol­en, kein Download mehr:
      await CloudSyncManager.fetchRemoteSyncFlag();

      _navigateToHome(user);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        final email = e.email!;
        final pendingCred = e.credential!;
        final password = await _askForPassword(email);
        if (password == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Verknüpfung abgebrochen')),
          );
          return;
        }
        try {
          final userCred = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
          final user = userCred.user!;
          await user.linkWithCredential(pendingCred);
          await _ensureUserDoc(user, 'google');

          await CloudSyncManager.fetchRemoteSyncFlag();

          _navigateToHome(user);
        } on FirebaseAuthException catch (e2) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verknüpfung fehlgeschlagen: ${e2.message}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In fehlgeschlagen: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Zeigt einen Dialog, um das Passwort abzufragen
  Future<String?> _askForPassword(String email) {
    final _pwController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passwort benötigt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Für $email existiert bereits ein Konto.\n'
                'Bitte Passwort eingeben, um die Konten zu verknüpfen.'),
            const SizedBox(height: 8),
            TextField(
              controller: _pwController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Passwort'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_pwController.text),
            child: const Text('Verknüpfen'),
          ),
        ],
      ),
    );
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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Transform.scale(
            scale: 1.3,
            child: Image.asset('assets/Pfeil_Back.png', width: 24, height: 24),
          ),
          onPressed: () => Navigator.of(context).pop(),
          splashRadius: 24,
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      validator: (v) => (v != null &&
                          v.length >= 8 &&
                          RegExp(r'\d').hasMatch(v))
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
                          MaterialPageRoute(
                              builder: (_) => const ResetPasswordPage()),
                        ),
                        child: const Text(
                          'Passwort vergessen?',
                          style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
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
                GoogleAuthButton(text: 'Mit Google anmelden', onPressed: _googleLogin),
              ],
            ),
          ),

          // Lade-Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
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
  bool _isLoading = false;

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

  Future<void> _ensureUserDoc(User user, String provider) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snap = await doc.get();
    if (!snap.exists) {
      await doc.set({
        'email': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': provider,
      });
    }
  }

  Future<void> _emailRegister() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: _email, password: _password);
      await _ensureUserDoc(cred.user!, 'password');

      // Nur Flag holen, kein Download:
      await CloudSyncManager.fetchRemoteSyncFlag();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(firstName: _email, lastName: '')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registrierung fehlgeschlagen: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleRegister() async {
    setState(() => _isLoading = true);
    try {
      final cred = await AuthHelpers.signInWithGoogle() as UserCredential;
      final user = cred.user!;
      await _ensureUserDoc(user, 'google');

      await CloudSyncManager.fetchRemoteSyncFlag();

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomePage(firstName: user.email ?? '', lastName: '')),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-Up fehlgeschlagen: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _bulletColor(bool valid) => valid ? Colors.green : Colors.red;

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
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                        Expanded(
                          child: Text('Mindestlänge 8 Zeichen',
                              style: TextStyle(color: _bulletColor(_isLengthValid))),
                        ),
                      ]),
                      Row(children: [
                        Text('• ', style: TextStyle(color: _bulletColor(_hasNumber))),
                        Expanded(
                          child: Text('Mindestens 1 Zahl',
                              style: TextStyle(color: _bulletColor(_hasNumber))),
                        ),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Konto erstellen', style: TextStyle(color: Colors.white)),
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
                GoogleAuthButton(text: 'Mit Google registrieren', onPressed: _googleRegister),
              ],
            ),
          ),

          // Lade-Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
