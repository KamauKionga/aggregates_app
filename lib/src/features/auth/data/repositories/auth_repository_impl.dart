import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource _ds;

  AuthRepositoryImpl(FirebaseAuth auth, FirebaseFirestore firestore)
    : _ds = FirebaseAuthDataSource(auth, firestore);

  @override
  Future<AppUser?> getCurrentUser() => _ds.getCurrentUser();

  @override
  Stream<AppUser?> authStateChanges() => _ds.authStateChanges();

  @override
  Future<AppUser> signInWithEmail(String email, String password) =>
      _ds.signInWithEmail(email, password);

  @override
  Future<AppUser> signUpWithEmail(
    String email,
    String password, {
    required String role,
  }) => _ds.signUpWithEmail(email, password, role: role);

  @override
  Future<AppUser> signInWithGoogle({required String role}) =>
      _ds.signInWithGoogle(role: role);

  @override
  Future<AppUser> signInWithApple({required String role}) =>
      _ds.signInWithApple(role: role);

  @override
  Future<void> signOut() => _ds.signOut();

  @override
  Future<void> requestPhoneVerification(
    String phoneNumber,
    void Function(String verificationId) codeSent,
  ) => _ds.requestPhoneVerification(phoneNumber, codeSent);

  @override
  Future<AppUser> verifySmsCode(
    String verificationId,
    String smsCode, {
    required String role,
  }) => _ds.verifySmsCode(verificationId, smsCode, role: role);
}
