import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../aggregates_providers.dart';
import '../../auth/auth_providers.dart';
import '../../auth/domain/models/user_role.dart';

class AdminPricingScreen extends ConsumerStatefulWidget {
  const AdminPricingScreen({super.key});

  @override
  ConsumerState<AdminPricingScreen> createState() => _AdminPricingScreenState();
}

class _AdminPricingScreenState extends ConsumerState<AdminPricingScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(defaultAggregateProductsProvider);
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        final role = user?.role;
        final isAdmin = role == UserRole.admin;
        final isQuarry = role == UserRole.quarry;

        return Scaffold(
          appBar: AppBar(title: const Text('Pricing (Admin)')),
          body: ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, i) {
              final p = products[i];
              final ctrl = _controllers.putIfAbsent(
                p.id,
                () => TextEditingController(),
              );

              return FutureBuilder<double>(
                future: ref.read(priceForProductProvider(p.id).future),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done)
                    return ListTile(
                      title: Text(p.name),
                      trailing: const SizedBox(
                        width: 80,
                        child: LinearProgressIndicator(),
                      ),
                    );
                  final val = snap.data ?? 1100.0;
                  if (!ctrl.text.isNotEmpty) ctrl.text = val.toStringAsFixed(0);

                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text(p.sizeLabel),
                    trailing: SizedBox(
                      width: 160,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              keyboardType: TextInputType.number,
                              enabled: isAdmin && !isQuarry,
                              decoration: const InputDecoration(
                                suffixText: 'Ksh/ton',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: (!isAdmin || _saving)
                                ? null
                                : () async {
                                    final text = ctrl.text.trim();
                                    final value = double.tryParse(text);
                                    if (value == null || value <= 0) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Invalid price'),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() => _saving = true);
                                    try {
                                      await ref
                                          .read(pricingRepositoryProvider)
                                          .setPrice(p.id, value);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(content: Text('Saved')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Save failed: $e'),
                                        ),
                                      );
                                    } finally {
                                      setState(() => _saving = false);
                                    }
                                  },
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Scaffold(body: Center(child: Text('Auth error'))),
    );
  }
}
