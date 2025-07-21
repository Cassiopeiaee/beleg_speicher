// lib/auth_helpers.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Eine Hilfsklasse für Firebase- und Google-Authentifizierung.
class AuthHelpers {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Meldet den Benutzer über Google an und liefert das zugehörige
  /// [UserCredential] von Firebase.
  ///
  /// Wirft eine [FirebaseAuthException], wenn der Nutzer den Flow abbricht
  /// oder ein sonstiger Auth-Fehler auftritt.
  static Future<UserCredential> signInWithGoogle() async {
    // 1) Google-SignIn-Flow starten
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Google Sign-In vom Nutzer abgebrochen.',
      );
    }

    // 2) Authentifizierungs-Tokens abrufen
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    if (googleAuth.accessToken == null || googleAuth.idToken == null) {
      throw FirebaseAuthException(
        code: 'ERROR_MISSING_GOOGLE_AUTH_TOKEN',
        message: 'Fehlende Google Auth Tokens.',
      );
    }

    // 3) Firebase-Credential aus den Tokens erstellen
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4) Anmeldung bei Firebase mit dem Google-Credential
    return _auth.signInWithCredential(credential);
  }

  /// Meldet den aktuell angemeldeten Benutzer ab.
  /// Versucht zuerst, Google abzumelden, und dann Firebase Auth.
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Fehler beim Google-Abmelden ignorieren
    }
    await _auth.signOut();
  }

  /// Liefert den aktuell angemeldeten Firebase-Benutzer oder null,
  /// wenn keiner angemeldet ist.
  static User? get currentUser => _auth.currentUser;
}
