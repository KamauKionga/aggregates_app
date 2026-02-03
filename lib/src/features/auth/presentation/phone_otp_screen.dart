import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_providers.dart';

class PhoneOtpScreen extends ConsumerStatefulWidget {
  const PhoneOtpScreen({super.key});

  @override
  ConsumerState<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends ConsumerState<PhoneOtpScreen> {
  final _phoneCtl = TextEditingController();
  final _codeCtl = TextEditingController();
  String? _verificationId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Sign-In')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _phoneCtl,
              decoration: const InputDecoration(labelText: 'Phone (+country)'),
              keyboardType: TextInputType.phone,
            ),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).requestPhoneVerification(
                  _phoneCtl.text.trim(),
                  (verificationId) {
                    setState(() => _verificationId = verificationId);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Code sent')));
                  },
                );
              },
              child: const Text('Request Code'),
            ),
            TextField(
              controller: _codeCtl,
              decoration: const InputDecoration(labelText: 'SMS Code'),
            ),
            ElevatedButton(
              onPressed: _verificationId == null
                  ? null
                  : () async {
                      try {
                        await ref
                            .read(authRepositoryProvider)
                            .verifySmsCode(
                              _verificationId!,
                              _codeCtl.text.trim(),
                              role: 'buyer',
                            );
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    },
              child: const Text('Verify Code'),
            ),
          ],
        ),
      ),
    );
  }
}
