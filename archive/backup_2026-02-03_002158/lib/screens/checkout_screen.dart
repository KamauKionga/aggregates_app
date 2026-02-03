import 'package:flutter/material.dart';
import '../services/order_service.dart';
import 'receipt_screen.dart';
import 'chat_screen.dart';

class CheckoutScreen extends StatelessWidget {
  final Map<String, dynamic> invoice;
  const CheckoutScreen({super.key, required this.invoice});

  Future<void> _completePayment(BuildContext context, String method) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$method payment simulated')));

    final order = await OrderService.createOrder(invoice);

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ReceiptScreen(order: order)),
    );
  }

  void _payWithMpesa(BuildContext context) {
    // open dialog to enter phone and simulate STK
    showDialog(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('MPESA STK'),
          content: TextField(
            key: const ValueKey('mpesa_phone'),
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Enter phone (e.g. 07...)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('mpesa_send'),
              onPressed: () {
                Navigator.pop(context);
                _completePayment(context, 'MPESA');
              },
              child: const Text('Send STK'),
            ),
          ],
        );
      },
    );
  }

  void _payWithCard(BuildContext context) {
    // show simple card dialog
    showDialog(
      context: context,
      builder: (_) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Card Payment (Mock)'),
          content: TextField(
            key: const ValueKey('card_number'),
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Card number'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('card_pay'),
              onPressed: () {
                Navigator.pop(context);
                _completePayment(context, 'Card');
              },
              child: const Text('Pay'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total =
        (invoice['aggregatesCost'] as int) + (invoice['transportCost'] as int);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
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
            Text(
              'Amount to pay: Kshs. $total',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose payment method',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              key: const ValueKey('pay_mpesa'),
              onPressed: () => _payWithMpesa(context),
              child: const Text('Pay with MPESA (STK)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              key: const ValueKey('pay_card'),
              onPressed: () => _payWithCard(context),
              child: const Text('Pay with Visa / Card'),
            ),
          ],
        ),
      ),
    );
  }
}
