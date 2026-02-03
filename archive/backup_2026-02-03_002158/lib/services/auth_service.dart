import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static Future<UserCredential> signInWithGoogle() async {
    // Provider-based sign-in. Ensure Google sign-in is enabled in Firebase console and native settings are configured.
    final provider = GoogleAuthProvider();
    return await _auth.signInWithProvider(provider);
  }

  static Future<UserCredential> createAccountWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (displayName != null && displayName.isNotEmpty) {
      await userCred.user?.updateDisplayName(displayName);
    }

    await userCred.user?.sendEmailVerification();

    return userCred;
  }

  static Future<UserCredential> signInWithEmail(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> sendSignInLinkToEmail(
    String email, {
    String url = 'https://yourapp.page.link/signin',
    String androidPackageName = 'com.example.aggregates_app',
    String iOSBundleId = 'com.example.aggregatesApp',
  }) async {
    final action = ActionCodeSettings(
      url: url,
      handleCodeInApp: true,
      androidPackageName: androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: iOSBundleId,
    );
    await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: action);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email_for_sign_in', email);
  }

  static Future<UserCredential> signInWithEmailLink(
    String email,
    String emailLink,
  ) async {
    return await _auth.signInWithEmailLink(email: email, emailLink: emailLink);
  }

  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'No signed in user',
      );
    }
  }

  static Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  static Future<void> signOut() => _auth.signOut();
}
