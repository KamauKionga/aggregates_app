import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../domain/entities/app_user.dart';
import '../../data/firestore_user_schema.dart';
import '../../domain/models/user_role.dart';

class FirebaseAuthDataSource {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthDataSource(
    this._auth,
    this._firestore, {
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn();

  Stream<AppUser?> authStateChanges() =>
      _auth.authStateChanges().asyncMap((fb.User? user) async {
        if (user == null) return null;
        final doc = await _firestore
            .collection(usersCollection)
            .doc(user.uid)
            .get();
        if (doc.exists) return AppUser.fromMap(doc.data()!..['uid'] = user.uid);
        // Create minimal profile on first sign-in
        final appUser = AppUser(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          phoneNumber: user.phoneNumber,
          role: UserRole.buyer,
        );
        await _firestore
            .collection(usersCollection)
            .doc(user.uid)
            .set(appUser.toMap());
        return appUser;
      });

  Future<AppUser?> getCurrentUser() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _firestore.collection(usersCollection).doc(u.uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!..['uid'] = u.uid;
    return AppUser.fromMap(data);
  }

  Future<AppUser> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return await _ensureUserDoc(cred.user!);
  }

  Future<AppUser> signUpWithEmail(
    String email,
    String password, {
    required String role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final roleEnum = UserRoleX.fromString(role);
    final user = AppUser(uid: cred.user!.uid, email: email, role: roleEnum);
    await _firestore
        .collection(usersCollection)
        .doc(user.uid)
        .set(user.toMap());
    return user;
  }

  Future<AppUser> signInWithGoogle({required String role}) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign in aborted');
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final appUser = await _ensureUserDoc(cred.user!, role: role);
    return appUser;
  }

  Future<AppUser> signInWithApple({required String role}) async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final oAuthProvider = fb.OAuthProvider('apple.com');
    final authCredential = oAuthProvider.credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );
    final cred = await _auth.signInWithCredential(authCredential);
    final appUser = await _ensureUserDoc(cred.user!, role: role);
    return appUser;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> requestPhoneVerification(
    String phoneNumber,
    void Function(String verificationId) codeSent,
  ) async {
    // For mobile platforms this uses native verification callbacks.
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) {},
      verificationFailed: (e) => throw e,
      codeSent: (verificationId, resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (verificationId) {},
    );
  }

  Future<AppUser> verifySmsCode(
    String verificationId,
    String smsCode, {
    required String role,
  }) async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final cred = await _auth.signInWithCredential(credential);
    final appUser = await _ensureUserDoc(cred.user!, role: role);
    return appUser;
  }

  Future<AppUser> _ensureUserDoc(fb.User user, {String? role}) async {
    final docRef = _firestore.collection(usersCollection).doc(user.uid);
    final snap = await docRef.get();
    if (snap.exists) {
      final map = snap.data()!..['uid'] = user.uid;
      return AppUser.fromMap(map);
    }
    final roleVal = role != null ? UserRoleX.fromString(role) : UserRole.buyer;
    final appUser = AppUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      role: roleVal,
      agentApproved: roleVal == UserRole.agent ? false : true,
      referredByAgentId: (snap.data() ?? {})['referredByAgentId'] as String?,
    );
    await docRef.set(appUser.toMap());
    return appUser;
  }
}
