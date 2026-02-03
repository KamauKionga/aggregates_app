import '../../domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<AppUser?> getCurrentUser();

  Future<AppUser> signInWithEmail(String email, String password);
  Future<AppUser> signUpWithEmail(
    String email,
    String password, {
    required String role,
  });

  Future<AppUser> signInWithGoogle({required String role});
  Future<AppUser> signInWithApple({required String role});

  Future<void> signOut();

  // Phone auth flow: request code and verify
  Future<void> requestPhoneVerification(
    String phoneNumber,
    void Function(String verificationId) codeSent,
  );
  Future<AppUser> verifySmsCode(
    String verificationId,
    String smsCode, {
    required String role,
  });
}
