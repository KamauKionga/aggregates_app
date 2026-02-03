import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../Models/order.dart';
import 'order_detail_screen.dart';
import 'chat_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  Future<void> _load() async {
    final list = await OrderService.getUndeliveredOrders();
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
          ? const Center(child: Text('No active orders'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (context, i) {
                  final o = _orders[i];
                  return ListTile(
                    title: Text('Order ${o.id} — ${o.invoice['type']}'),
                    subtitle: Text('Status: ${o.status}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(orderId: o.id),
                      ),
                    ).then((_) => _load()),
                  );
                },
              ),
            ),
    );
  }
}
