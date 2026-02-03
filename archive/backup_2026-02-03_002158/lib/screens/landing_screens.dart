import 'package:flutter/material.dart';
import '../Models/user_roles.dart';
import 'signup_screen.dart';
import 'trucker_type_selection_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  void goToSignup(BuildContext context, UserRole role) {
    if (role == UserRole.trucker) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TruckerTypeSelectionScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignupScreen(role: role)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Get Started')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Who are you?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            _roleButton(context, 'Buyer', Icons.shopping_cart, UserRole.buyer),
            _roleButton(context, 'Agent', Icons.support_agent, UserRole.agent),
            _roleButton(
              context,
              'Trucker',
              Icons.local_shipping,
              UserRole.trucker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleButton(
    BuildContext context,
    String label,
    IconData icon,
    UserRole role,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        key: ValueKey('role_$label'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 56),
        ),
        icon: Icon(icon),
        label: Text(label),
        onPressed: () => goToSignup(context, role),
      ),
    );
  }
}
