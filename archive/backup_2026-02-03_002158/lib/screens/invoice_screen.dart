import 'package:flutter/material.dart';
import 'checkout_screen.dart';
import 'chat_screen.dart';

class InvoiceScreen extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const InvoiceScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final aggregatesCost = invoice['aggregatesCost'] as int;
    final transportCost = invoice['transportCost'] as int;
    final total = aggregatesCost + transportCost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${invoice['type']}'),
            const SizedBox(height: 4),
            const SizedBox(height: 8),
            Text('Tonnage: ${invoice['tons']} tons'),
            const SizedBox(height: 8),
            Text('Price per ton: Kshs. ${invoice['pricePerTon']}'),
            const SizedBox(height: 8),
            Text('Aggregates cost: Kshs. $aggregatesCost'),
            const SizedBox(height: 8),
            Text('Transport cost: Kshs. $transportCost'),
            const SizedBox(height: 12),
            Text(
              'Total: Kshs. $total',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutScreen(invoice: invoice),
                  ),
                );
              },
              key: const ValueKey('proceed_to_checkout'),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}
