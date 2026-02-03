import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../Models/order.dart';
import '../services/order_service.dart';
import 'chat_screen.dart';
import 'buyer_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  Timer? _timer;

  Future<void> _load() async {
    final ord = await OrderService.getOrder(widget.orderId);
    if (!mounted) return;
    setState(() => _order = ord);
  }

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _feedbackController.dispose();
    super.dispose();
  }

  int _selectedRating = 5;
  final TextEditingController _feedbackController = TextEditingController();

  Future<void> _submitRating() async {
    if (_order == null) return;
    await OrderService.addRating(
      _order!.id,
      _selectedRating,
      _feedbackController.text.trim(),
    );
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Thanks for your feedback')));
  }

  Widget _buildTimeline(String status, Map<String, String> timeline) {
    final stages = [
      'Scheduled',
      'Loading',
      'In Transit',
      'Out for Delivery',
      'Delivered',
    ];
    return Column(
      children: stages.map((s) {
        final idx = stages.indexOf(s);
        final curr = stages.indexOf(status);
        final done = curr >= idx;
        final ts = timeline[s];
        final subtitle = ts != null
            ? DateFormat.yMMMd().add_jm().format(DateTime.parse(ts))
            : null;
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: done ? Colors.green : Colors.grey.shade300,
            child: done
                ? const Icon(Icons.check, color: Colors.white)
                : Text('${idx + 1}'),
          ),
          title: Text(s),
          subtitle: subtitle != null ? Text(subtitle) : null,
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_order == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final ord = _order!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order ID: ${ord.id}'),
            Text(
              'Created: ${DateFormat.yMMMd().add_jm().format(ord.createdAt)}',
            ),
            const SizedBox(height: 8),
            Text(
              'Status: ${ord.status}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Estimated delivery: ${ord.estimatedDelivery != null ? DateFormat.yMMMd().add_jm().format(ord.estimatedDelivery!) : 'N/A'}',
            ),
            const SizedBox(height: 16),
            const Text(
              'Progress:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: _buildTimeline(ord.status, ord.timeline),
              ),
            ),
            const SizedBox(height: 8),
            if (ord.status.toLowerCase() == 'delivered' &&
                ord.rating == null) ...[
              const Text(
                'Rate your experience',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  return IconButton(
                    icon: Icon(
                      idx <= _selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () => setState(() => _selectedRating = idx),
                  );
                }),
              ),
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional comments (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _submitRating,
                child: const Text('Submit Feedback'),
              ),
            ] else if (ord.rating != null) ...[
              Text('You rated: ${ord.rating} / 5'),
              if (ord.feedback != null && ord.feedback!.isNotEmpty)
                Text('Comments: ${ord.feedback}'),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(onPressed: _load, child: const Text('Refresh')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const BuyerOrderScreen()),
                  ),
                  child: const Text('Place another order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
