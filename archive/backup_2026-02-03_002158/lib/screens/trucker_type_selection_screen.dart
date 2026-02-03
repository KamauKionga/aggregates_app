import 'package:flutter/material.dart';
import '../Models/enums.dart';
import '../Models/user_roles.dart';
import 'signup_screen.dart';

class TruckerTypeSelectionScreen extends StatelessWidget {
  const TruckerTypeSelectionScreen({super.key});

  void _goToSignup(BuildContext context, TruckerType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupScreen(role: UserRole.trucker, truckerType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trucker Type')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Are you an individual trucker or a fleet/company?'),
            const SizedBox(height: 24),
            ElevatedButton(
              key: const ValueKey('individual_trucker'),
              onPressed: () => _goToSignup(context, TruckerType.individual),
              child: const Text('Individual Trucker'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const ValueKey('organization_trucker'),
              onPressed: () => _goToSignup(context, TruckerType.organization),
              child: const Text('Organization / Fleet Company'),
            ),
          ],
        ),
      ),
    );
  }
}
