import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/order.dart' as ord;

String? _fmt(dynamic v) {
  if (v == null) return null;
  if (v is Timestamp)
    return DateTime.fromMillisecondsSinceEpoch(
      v.millisecondsSinceEpoch,
    ).toLocal().toString();
  if (v is DateTime) return v.toLocal().toString();
  return v.toString();
}

class OrderTimeline extends StatelessWidget {
  final ord.Order order;
  const OrderTimeline({super.key, required this.order});

  Widget _buildStep({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool done,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(icon, color: done ? Colors.green : Colors.grey),
            const SizedBox(height: 4),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = order.timeline;
    final createdAt = order.createdAt;
    final paidAt = timeline['paidAt'];
    final truckAssignedAt =
        timeline['truckAssignedAt'] ?? timeline['truckAssigned'];
    final loadingAt = timeline['loadingAt'];
    final inTransitAt = timeline['inTransitAt'];
    final outForDeliveryAt =
        timeline['outForDeliveryAt'] ?? timeline['truckAssignedAt'];
    final deliveredAt = order.deliveredAt ?? timeline['deliveredAt'];

    final steps = <Widget>[
      _buildStep(
        icon: Icons.add_shopping_cart,
        title: 'Order placed',
        subtitle: _fmt(createdAt),
        done: true,
      ),
      _buildStep(
        icon: Icons.payment,
        title: 'Paid',
        subtitle: _fmt(paidAt),
        done: paidAt != null,
      ),
      _buildStep(
        icon: Icons.local_shipping,
        title: 'Truck assigned',
        subtitle: _fmt(truckAssignedAt),
        done: truckAssignedAt != null,
      ),
      _buildStep(
        icon: Icons.inventory,
        title: 'Loading',
        subtitle: _fmt(loadingAt),
        done: loadingAt != null,
      ),
      _buildStep(
        icon: Icons.directions_bus,
        title: 'In transit',
        subtitle: _fmt(inTransitAt),
        done: inTransitAt != null,
      ),
      _buildStep(
        icon: Icons.location_on,
        title: 'Out for delivery',
        subtitle: _fmt(outForDeliveryAt),
        done: outForDeliveryAt != null,
      ),
      _buildStep(
        icon: Icons.verified,
        title: 'Delivered',
        subtitle: _fmt(deliveredAt),
        done: deliveredAt != null,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...steps,
          ],
        ),
      ),
    );
  }
}
