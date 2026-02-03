import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../quarries_providers.dart';
import '../../orders/orders_providers.dart';

class AdminReassignmentScreen extends ConsumerWidget {
  const AdminReassignmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersRepo = ref.read(ordersRepositoryProvider);
    final quarriesRepo = ref.read(quarriesRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Assign Quarry')),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Seed Kayole'),
        icon: const Icon(Icons.add_location_alt),
        onPressed: () async {
          try {
            final q = await quarriesRepo.seedKayoleIfNotExists();
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Seeded quarry: ${q.name}')));
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to seed: $e')));
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: FutureBuilder<List>(
          future: ordersRepo.getUndeliveredOrders(),
          builder: (context, ordersSnap) {
            if (ordersSnap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (ordersSnap.hasError)
              return Center(child: Text('Error: ${ordersSnap.error}'));
            final orders = ordersSnap.data ?? [];
            return FutureBuilder<List>(
              future: quarriesRepo.getAllActiveQuarries(),
              builder: (context, qSnap) {
                if (qSnap.connectionState != ConnectionState.done)
                  return const Center(child: CircularProgressIndicator());
                if (qSnap.hasError)
                  return Center(child: Text('Error: ${qSnap.error}'));
                final quarries = qSnap.data ?? [];

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) {
                    final o = orders[i];
                    return Card(
                      child: ListTile(
                        title: Text('Order ${o.id} — ${o.status.name}'),
                        subtitle: Text(
                          'Assigned quarry: ${(o.assignedQuarryId ?? 'None')}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_location),
                          onPressed: () async {
                            final chosen = await showDialog<String?>(
                              context: context,
                              builder: (ctx) => SimpleDialog(
                                title: const Text('Choose quarry'),
                                children: quarries
                                    .map(
                                      (qq) => SimpleDialogOption(
                                        child: Text(qq.name),
                                        onPressed: () =>
                                            Navigator.pop(ctx, qq.id),
                                      ),
                                    )
                                    .toList(),
                              ),
                            );

                            if (chosen != null) {
                              await ref
                                  .read(ordersRepositoryProvider)
                                  .assignQuarry(o.id, chosen);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Quarry reassigned'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
