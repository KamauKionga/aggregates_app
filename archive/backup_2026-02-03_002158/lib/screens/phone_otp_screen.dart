import 'package:flutter/material.dart';
import 'buyer_order_screen.dart';
import '../Models/user_roles.dart';
import '../Models/enums.dart';
import 'individual_onboarding_screen.dart';
import 'organization_onboarding_screen.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String phone;
  final UserRole role;
  final TruckerType? truckerType;
  const PhoneOtpScreen({super.key, required this.phone, required this.role, this.truckerType}) : super();

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _verifyOtp() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter OTP')));
      return;
    }

    // TODO: integrate real OTP verification
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('OTP verified (stub)')));

    // Route based on role/trucker type
    if (widget.role == UserRole.trucker) {
      if (widget.truckerType == TruckerType.individual) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => IndividualOnboardingScreen(userId: widget.phone, email: '', phone: widget.phone)),
        );
        return;
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OrganizationOnboardingScreen(userId: widget.phone, email: '', phone: widget.phone)),
        );
        return;
      }
    }

    // Default to buyer orders
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BuyerOrderScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Phone')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter the 6-digit code sent to ${widget.phone}'),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('otp_code'),
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'OTP Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _verifyOtp, child: const Text('Verify')),
          ],
        ),
      ),
    );
  }
}

// removed redirect placeholder
