import 'package:flutter/material.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _card(context, 'User Approvals', '/admin/users', Icons.person_search),
            _card(context, 'Pricing', '/admin/pricing', Icons.price_check),
            _card(context, 'Assignments', '/admin/assign-quarry', Icons.place),
            _card(context, 'Wallets', '/admin/wallets', Icons.account_balance_wallet),
            _card(context, 'Reports', '/admin/reports', Icons.insert_chart),
            _card(context, 'Disputes', '/admin/disputes', Icons.report_problem),
            _card(context, 'Analytics', '/admin/analytics', Icons.analytics),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, String title, String route, IconData icon) {
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(route),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Icon(icon, size: 42), const SizedBox(height: 12), Text(title, style: const TextStyle(fontWeight: FontWeight.bold))],
          ),
        ),
      ),
    );
  }
}