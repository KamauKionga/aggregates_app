import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_service.dart';
import '../../auth/auth_providers.dart';

class AdminWalletsScreen extends ConsumerStatefulWidget {
  const AdminWalletsScreen({super.key});

  @override
  AdminWalletsScreenState createState() => AdminWalletsScreenState();
}

class AdminWalletsScreenState extends ConsumerState<AdminWalletsScreen> {
  List<Map<String, dynamic>> _withdrawals = [];
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = AdminService(ref.read(firebaseFirestoreProvider));
    final res = await svc.listWithdrawals();
    setState(() {
      _withdrawals = res;
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
      appBar: AppBar(title: const Text('Wallets - Withdrawals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _withdrawals.isEmpty
              ? const Center(child: Text('No pending withdrawals'))
              : ListView.builder(
                  itemCount: _withdrawals.length,
                  itemBuilder: (c, i) {
                    final w = _withdrawals[i];
                    return Card(
                      child: ListTile(
                        title: Text('Withdrawal ${w['id']} • Ksh ${w['amount']}'),
                        subtitle: Text('Wallet: ${w['walletId']} • Requested by: ${w['requestedBy'] ?? 'unknown'}'),
                        trailing: ElevatedButton(
                          child: const Text('Approve'),
                          onPressed: () async {
                            try {
                              final admin = ref.read(authStateChangesProvider).asData?.value;
                              if (admin == null) return;
                              await AdminService(ref.read(firebaseFirestoreProvider)).approveWithdrawal(w['id'] as String, admin.uid);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Withdrawal approved')));
                              await _load();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}