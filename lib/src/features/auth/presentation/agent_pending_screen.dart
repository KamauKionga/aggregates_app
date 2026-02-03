import 'package:flutter/material.dart';

class AgentPendingScreen extends StatelessWidget {
  const AgentPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agent Approval Pending')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Your account is pending admin approval. You will be notified when an admin approves your account.',
          ),
        ),
      ),
    );
  }
}
