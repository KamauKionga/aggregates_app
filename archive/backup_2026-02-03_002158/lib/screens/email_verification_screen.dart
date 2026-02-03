import 'package:flutter/material.dart';
import 'buyer_order_screen.dart';
import '../services/auth_service.dart';
import '../services/trucker_repository.dart';
import '../Models/enums.dart';
import 'individual_onboarding_screen.dart';
import 'organization_onboarding_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _sending = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    // Ensure a verification email has been sent
    _sendVerificationEmail();
  }

  Future<void> _sendVerificationEmail() async {
    setState(() => _sending = true);
    try {
      await AuthService.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Verification email sent')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerified() async {
    setState(() => _checking = true);
    try {
      await AuthService.reloadUser();
      if (!mounted) return;
      final user = AuthService.currentUser;
      if (user != null && user.emailVerified) {
        // If user is a trucker with a pending profile, route to trucker flows
        final t = await TruckerRepository.getByUserId(user.uid);
        if (!mounted) return;
        if (t != null) {
          if (t.type == TruckerType.individual) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DocumentUploadScreen(truckerId: t.id, requiredDocs: t.documents)),
            );
            return;
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => OrganizationOnboardingScreen(userId: user.uid, email: user.email ?? '', phone: user.phoneNumber ?? '')),
            );
            return;
          }
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const BuyerOrderScreen()),
        );
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email not verified yet. Please check your inbox and click the verification link.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A verification email has been sent to ${widget.email}. Click the link in the email to verify your address.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checking ? null : _checkVerified,
              child: _checking
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('I have verified — Check'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _sending ? null : _sendVerificationEmail,
              child: _sending
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Resend verification email'),
            ),
          ],
        ),
      ),
    );
  }
}
