import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_providers.dart';
import '../orders_providers.dart';
import '../domain/order.dart' as ord;
import 'order_timeline.dart';
import '../../../utils/eta_utils.dart';
import '../../../utils/geo_utils.dart';
import '../../reports/presentation/receipt_widgets.dart';

class BuyerTrackingScreen extends ConsumerWidget {
  final String orderId;
  const BuyerTrackingScreen({super.key, required this.orderId});

  String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderStreamProvider(orderId));
    final authState = ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Track Order')),
      body: orderAsync.when(
        data: (order) {
          // Destination location from invoice
          final dest =
              (order.invoice['deliveryLocation'] as Map<String, dynamic>?);

          // Stream for truck location if assigned
          Stream<DocumentSnapshot<Map<String, dynamic>>>? truckLocStream;
          if ((order.assignedTruckId ?? '').isNotEmpty) {
            truckLocStream = ref
                .read(firebaseFirestoreProvider)
                .collection('truck_locations')
                .doc(order.assignedTruckId)
                .snapshots();
          }

          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: ${order.status.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (truckLocStream != null && dest != null)
                          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                            stream: truckLocStream,
                            builder: (context, snap) {
                              if (!snap.hasData || !snap.data!.exists)
                                return const Text('Location unavailable');
                              final d = snap.data!.data()!;
                              final lat = (d['lat'] as num).toDouble();
                              final lng = (d['lng'] as num).toDouble();
                              final destLat = (dest['lat'] as num).toDouble();
                              final destLng = (dest['lng'] as num).toDouble();
                              final remaining = haversineDistanceKm(
                                lat,
                                lng,
                                destLat,
                                destLng,
                              );
                              final eta = estimateEtaRange(remaining);
                              final early = _fmtTime(
                                eta['earliest']!.toLocal(),
                              );
                              final late = _fmtTime(eta['latest']!.toLocal());

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Distance remaining: ${remaining.toStringAsFixed(2)} km',
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Estimated arrival: $early — $late (approx.)',
                                  ),
                                ],
                              );
                            },
                          )
                        else if (order.distanceKm != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distance: ${order.distanceKm!.toStringAsFixed(2)} km',
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'ETA: ${_fmtEtaFromDistance(order.distanceKm!)}',
                              ),
                            ],
                          )
                        else
                          const Text('Distance / ETA not available'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OrderTimeline(order: order),
                const SizedBox(height: 12),
                // Receipt download
                Row(
                  children: [
                    if (order.status == ord.OrderStatus.delivered)
                      ReceiptDownloadButton(orderId: order.id),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed('/orders/${order.id}/track'),
                      child: const Text('Open track route'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: authState.when(
                    data: (user) {
                      if (user == null)
                        return const Center(
                          child: Text('Sign in to see order history'),
                        );
                      final hist = ref.watch(userOrdersProvider(user.uid));
                      return hist.when(
                        data: (orders) {
                          final others = orders
                              .where((o) => o.id != order.id)
                              .toList();
                          return _buildHistoryList(others);
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (_, __) =>
                            const Center(child: Text('Failed loading history')),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => const Center(child: Text('Auth error')),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Load error: ${e.toString()}')),
      ),
    );
  }

  Widget _buildHistoryList(List<ord.Order> orders) {
    if (orders.isEmpty) return const Center(child: Text('No previous orders'));
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (c, i) {
        final o = orders[i];
        return Card(
          child: ListTile(
            title: Text('Order ${o.id} • ${o.status.name}'),
            subtitle: Text(
              'Total: Ksh ${o.totalAmount} • ${o.createdAt.toLocal().toString().split('.').first}',
            ),
            onTap: () {},
          ),
        );
      },
    );
  }

  String _fmtEtaFromDistance(double dKm) {
    final eta = estimateEtaRange(dKm);
    final e = eta['earliest']!.toLocal();
    final l = eta['latest']!.toLocal();
    final eStr =
        '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
    final lStr =
        '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
    return '$eStr - $lStr';
  }
}
