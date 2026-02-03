import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../auth/auth_providers.dart';
import '../../orders/orders_providers.dart';
import 'package:aggregates_app/services/trucker_repository.dart';
import 'package:aggregates_app/services/mock_storage_repository.dart';
import 'package:aggregates_app/services/upload_service.dart';
import '../trucker_providers.dart';
import '../../quarry/quarries_providers.dart';
import 'package:aggregates_app/src/utils/geo_utils.dart';

class TruckerDashboardScreen extends ConsumerStatefulWidget {
  const TruckerDashboardScreen({super.key});

  @override
  TruckerDashboardScreenState createState() => TruckerDashboardScreenState();
}

class TruckerDashboardScreenState
    extends ConsumerState<TruckerDashboardScreen> {
  String? _selectedTruckId;
  bool _tracking = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const Center(child: Text('Not signed in'));
        return FutureBuilder(
          future: _loadTruckerAndOrders(user.uid),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final data = snap.data as Map<String, dynamic>;
            final trucker = data['trucker'];
            final trucks = trucker?.trucks ?? [];
            final orders = data['orders'] as List? ?? [];

            return Scaffold(
              appBar: AppBar(title: const Text('Trucker Dashboard')),
              body: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${trucker?.email ?? 'Trucker'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Select Truck:'),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String?>(
                            isExpanded: true,
                            value:
                                _selectedTruckId ??
                                (trucks.isNotEmpty ? trucks.first.id : null),
                            items: trucks
                                .map<DropdownMenuItem<String>>(
                                  (t) => DropdownMenuItem(
                                    value: t.id,
                                    child: Text(
                                      '${t.registrationNumber} • ${t.payloadTons}t',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedTruckId = v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _selectedTruckId == null
                              ? null
                              : _toggleTracking,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _tracking
                                      ? 'Stop Tracking'
                                      : 'Start Tracking',
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Assigned Orders',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: orders.isEmpty
                          ? const Text('No orders assigned')
                          : ListView.builder(
                              itemCount: orders.length,
                              itemBuilder: (c, i) {
                                final o = orders[i];
                                return Card(
                                  child: ListTile(
                                    title: Text(
                                      'Order: ${o.id} • Status: ${o.status.name}',
                                    ),
                                    subtitle: Text(
                                      'Total: Ksh ${o.totalAmount}',
                                    ),
                                    trailing: ElevatedButton(
                                      child: const Text('Confirm Delivery'),
                                      onPressed: () =>
                                          _confirmDelivery(o.id, o),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Auth error')),
    );
  }

  Future<Map<String, dynamic>> _loadTruckerAndOrders(String uid) async {
    final trucker = await TruckerRepository.getByUserId(uid);
    final ordersRepo = ref.read(ordersRepositoryProvider);
    final orders = await ordersRepo.getOrdersForTrucker(uid);
    // default selected truck
    if (_selectedTruckId == null &&
        trucker != null &&
        trucker.trucks.isNotEmpty)
      _selectedTruckId = trucker.trucks.first.id;
    return {'trucker': trucker, 'orders': orders};
  }

  Future<void> _toggleTracking() async {
    setState(() => _loading = true);
    try {
      final gps = ref.read(gpsServiceProvider);
      if (_tracking) {
        await gps.stopTracking();
        setState(() => _tracking = false);
      } else {
        if (_selectedTruckId == null) return;
        await gps.startTracking(truckId: _selectedTruckId!);
        setState(() => _tracking = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tracking error: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelivery(String orderId, dynamic order) async {
    setState(() => _loading = true);
    try {
      // Simulate picking a photo and uploading via MockStorageRepository
      final storage = MockStorageRepository();
      final uploader = UploadService(storage: storage);
      final id = const Uuid().v4();
      final destination = 'orders/$orderId/proof/$id.jpg';
      // Simulate a single photo upload
      await for (final _ in uploader.uploadFile('dummy-path', destination)) {}
      final url = await storage.getDownloadUrl(destination);
      final quarryId = order.assignedQuarryId as String?;
      double distanceKm = 0.0;
      if (quarryId != null) {
        final qRepo = ref.read(quarriesRepositoryProvider);
        final q = await qRepo.getQuarryById(quarryId);
        final loc = order.invoice['deliveryLocation'] as Map<String, dynamic>?;
        if (q != null && loc != null) {
          distanceKm = haversineDistanceKm(
            q.lat,
            q.lng,
            (loc['lat'] as num).toDouble(),
            (loc['lng'] as num).toDouble(),
          );
        }
      }

      // call repository to finalize delivery
      await ref
          .read(ordersRepositoryProvider)
          .deliverOrder(
            orderId: orderId,
            distanceKm: distanceKm,
            proofPhotoUrls: [if (url != null) url],
          );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Delivery confirmed')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delivery error: ${e.toString()}')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
}
