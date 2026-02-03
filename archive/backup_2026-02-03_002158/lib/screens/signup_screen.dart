import 'package:flutter/material.dart';
import '../Models/user_roles.dart';
import 'phone_otp_screen.dart';
import 'email_verification_screen.dart';
import 'buyer_order_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/trucker_model.dart';
import '../Models/enums.dart';
import '../services/trucker_repository.dart';
import 'individual_onboarding_screen.dart';
import 'organization_onboarding_screen.dart';

enum _AuthMethod { email, google }

class SignupScreen extends StatefulWidget {
  final UserRole role;
  final TruckerType? truckerType;

  const SignupScreen({super.key, required this.role, this.truckerType});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

enum EmailAuthType { password, link }

class _SignupScreenState extends State<SignupScreen> {
  _AuthMethod _method = _AuthMethod.email;
  final EmailAuthType _emailAuthType = EmailAuthType.password;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _countyController = TextEditingController();
  final TextEditingController _townController = TextEditingController();
  bool _acceptedTerms = false;
  bool _acceptedDataPolicy = false;
  bool _loading = false;

  String get title {
    switch (widget.role) {
      case UserRole.buyer:
        return 'Buyer Signup';
      case UserRole.agent:
        return 'Agent Signup';
      case UserRole.trucker:
        return 'Trucker Signup';
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _loading = true);
    try {
      final cred = await AuthService.signInWithGoogle();
      if (!mounted) return;
      final user = cred.user;
      if (user != null) {
        await _routeAfterSignIn(user);
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleCreateAccount() async {
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (phone.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PhoneOtpScreen(phone: phone)),
      );
      return;
    }

    if (email.isNotEmpty) {
      setState(() => _loading = true);
      try {
        if (_emailAuthType == EmailAuthType.link) {
          await AuthService.sendSignInLinkToEmail(email);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign-in link sent to email')),
          );
          return;
        }

        if (password.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a password')),
          );
          return;
        }

        if (_confirmPasswordController.text != password) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match')),
          );
          return;
        }

        // For trucker signups, ensure they accepted policies
        if (widget.role == UserRole.trucker && (!_acceptedTerms || !_acceptedDataPolicy)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please accept the terms and data policy')),
          );
          return;
        }

        try {
          final cred = await AuthService.createAccountWithEmailAndPassword(
            email,
            password,
            displayName: _fullNameController.text.trim(),
          );

          // If this is a trucker sign up, create an initial TruckerModel placeholder
          if (widget.role == UserRole.trucker && widget.truckerType != null) {
            final t = TruckerModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: cred.user?.uid ?? email,
              email: email,
              phone: _phoneController.text.trim(),
              type: widget.truckerType!,
              county: _countyController.text.trim().isEmpty ? null : _countyController.text.trim(),
              town: _townController.text.trim().isEmpty ? null : _townController.text.trim(),
              acceptedTerms: _acceptedTerms,
              acceptedDataPolicy: _acceptedDataPolicy,
            );
            await TruckerRepository.saveTrucker(t);
          }

          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EmailVerificationScreen(email: email),
            ),
          );
          return;
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
                // try sign in
            final cred = await AuthService.signInWithEmail(email, password);
            if (!mounted) return;
            if (cred.user != null) {
              final user = cred.user!;
              // If not verified, route to verification screen which will then route to onboarding after verification
              if (!user.emailVerified) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmailVerificationScreen(email: email),
                  ),
                );
                return;
              }

              // Verified: route appropriately (trucker vs buyer)
              await _routeAfterSignIn(user);
              return;
            }
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Failed to create account')),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        if (mounted) setState(() => _loading = false);
      }

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter phone or email')),
    );
  }

  Future<void> _routeAfterSignIn(User user) async {
    // Try to find an existing trucker profile by UID
    var t = await TruckerRepository.getByUserId(user.uid);

    // If none found, but the current flow is a trucker signup, create a placeholder
    if (t == null && widget.role == UserRole.trucker && widget.truckerType != null) {
      final placeholder = TruckerModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        email: user.email ?? '',
        phone: user.phoneNumber ?? '',
        type: widget.truckerType!,
        verificationStatus: VerificationStatus.incomplete,
        documents: [],
        trucks: [],
        drivers: [],
        county: _countyController.text.trim().isEmpty ? null : _countyController.text.trim(),
        town: _townController.text.trim().isEmpty ? null : _townController.text.trim(),
        acceptedTerms: _acceptedTerms,
        acceptedDataPolicy: _acceptedDataPolicy,
      );
      await TruckerRepository.saveTrucker(placeholder);
      t = placeholder;
    }

    if (!mounted) return;

    if (t != null) {
      // Navigate into the trucker flows
      if (t.type == TruckerType.individual) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => IndividualOnboardingScreen(userId: user.uid, email: user.email ?? '', phone: user.phoneNumber ?? '')),
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

    // Default to buyer flow
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BuyerOrderScreen()),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            ToggleButtons(
              isSelected: [
                _method == _AuthMethod.email,
                _method == _AuthMethod.google,
              ],
              onPressed: (i) {
                setState(() {
                  _method = i == 0 ? _AuthMethod.email : _AuthMethod.google;
                });
              },
              borderRadius: BorderRadius.circular(8),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Email'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('Google'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_method == _AuthMethod.google) ...[
              ElevatedButton.icon(
                key: const ValueKey('google_button'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
                icon: SvgPicture.asset(
                  'assets/google_logo.svg',
                  height: 24,
                  width: 24,
                ),
                label: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continue with Google'),
                onPressed: _loading ? null : _handleGoogleSignup,
              ),
            ] else ...[
              _textField(
                'Full Name',
                key: const ValueKey('full_name'),
                controller: _fullNameController,
              ),
              _textField(
                'Phone Number',
                key: const ValueKey('phone_number'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixText: '+254 ',
              ),
              _textField(
                'Email',
                key: const ValueKey('email'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              _textField(
                'Password',
                key: const ValueKey('password'),
                controller: _passwordController,
              ),

              _textField(
                'Confirm Password',
                key: const ValueKey('confirm_password'),
                controller: _confirmPasswordController,
              ),

              if (widget.role == UserRole.trucker) ...[
                const SizedBox(height: 16),
                _textField(
                  'County',
                  key: const ValueKey('county'),
                  controller: _countyController,
                ),
                _textField(
                  'Town / Area',
                  key: const ValueKey('town'),
                  controller: _townController,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(
                      key: const ValueKey('accept_terms'),
                      value: _acceptedTerms,
                      onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                    ),
                    const Expanded(child: Text('I accept the Terms & Conditions')),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      key: const ValueKey('accept_data_policy'),
                      value: _acceptedDataPolicy,
                      onChanged: (v) => setState(() => _acceptedDataPolicy = v ?? false),
                    ),
                    const Expanded(child: Text('I accept the Data & Compliance Policy')),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                key: const ValueKey('create_account'),
                onPressed: _loading ? null : _handleCreateAccount,
                child: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _textField(
    String label, {
    Key? key,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        key: key,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefixText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
