// lib/reset_password.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

InputDecoration _buildInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
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
  );
}

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});
  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  bool _emailSent = false;

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // 1) Passe die URL an dein Firebase-Hosting an:
    final actionCodeSettings = ActionCodeSettings(
      url: 'https://beleg-speicher.firebaseapp.com/login',  // hier landet der Nutzer nach Reset
      handleCodeInApp: true,                                 // true = In-App Flow
      iOSBundleId: 'com.example.beleg_speicher',
      androidPackageName: 'com.example.beleg_speicher',
      androidInstallApp: true,
      androidMinimumVersion: '23',
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _email,
        actionCodeSettings: actionCodeSettings,
      );
      setState(() => _emailSent = true);
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler: ${e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Passwort zurücksetzen',
            style: TextStyle(color: Colors.black)),
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _emailSent
            ? Center(
          child: Text(
            'Ein Link zum Zurücksetzen wurde an $_email gesendet.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
        )
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: _buildInputDecoration('E-Mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) =>
                (v != null && v.contains('@')) ? null : 'Ungültige E-Mail',
                onSaved: (v) => _email = v!.trim(),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _sendResetLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Link senden',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
