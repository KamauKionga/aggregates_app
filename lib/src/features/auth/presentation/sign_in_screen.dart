import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_providers.dart';
import '../domain/models/user_role.dart';

/// Sign-in screen offering Email/Password, Phone, Google, Apple.
/// Agents are restricted to Google sign-in only and require admin approval.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.email),
              label: const Text('Sign in with Email'),
              onPressed: () => _showEmailSignIn(context, ref, UserRole.buyer),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.phone),
              label: const Text('Sign in with Phone'),
              onPressed: () =>
                  Navigator.of(context).pushNamed('/auth/phone-otp'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google (Buyer/Trucker/Quarry)'),
              onPressed: () =>
                  _signInWithGoogle(ref, context, role: UserRole.trucker),
            ),
            if (!kIsWeb)
              ElevatedButton.icon(
                icon: const Icon(Icons.apple),
                label: const Text('Sign in with Apple'),
                onPressed: () =>
                    _signInWithApple(ref, context, role: UserRole.buyer),
              ),
            const SizedBox(height: 24),
            const Text(
              'If you are an Agent you must use Google Sign-In and await admin approval.',
            ),
            ElevatedButton(
              child: const Text('Agent Sign-In (Google only)'),
              onPressed: () =>
                  _signInWithGoogle(ref, context, role: UserRole.agent),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailSignIn(BuildContext context, WidgetRef ref, UserRole role) {
    showDialog(
      context: context,
      builder: (context) {
        final emailCtl = TextEditingController();
        final passCtl = TextEditingController();
        return AlertDialog(
          title: const Text('Email sign in'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: emailCtl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passCtl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .signInWithEmail(
                        emailCtl.text.trim(),
                        passCtl.text.trim(),
                      );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Sign in'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signInWithGoogle(
    WidgetRef ref,
    BuildContext context, {
    required UserRole role,
  }) async {
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle(role: role.name);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
    }
  }

  Future<void> _signInWithApple(
    WidgetRef ref,
    BuildContext context, {
    required UserRole role,
  }) async {
    try {
      await ref.read(authRepositoryProvider).signInWithApple(role: role.name);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
    }
  }
}
