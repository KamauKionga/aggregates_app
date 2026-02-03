import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/admin_service.dart';
import '../../auth/auth_providers.dart';

class AdminDisputesScreen extends ConsumerStatefulWidget {
  const AdminDisputesScreen({super.key});

  @override
  AdminDisputesScreenState createState() => AdminDisputesScreenState();
}

class AdminDisputesScreenState extends ConsumerState<AdminDisputesScreen> {
  List<Map<String, dynamic>> _disputes = [];
  bool _loading = false;

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = AdminService(ref.read(firebaseFirestoreProvider));
    final res = await svc.listDisputes();
    setState(() {
      _disputes = res;
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
      appBar: AppBar(title: const Text('Disputes')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _disputes.isEmpty
              ? const Center(child: Text('No open disputes'))
              : ListView.builder(
                itemCount: _disputes.length,
                itemBuilder: (c, i) {
                  final d = _disputes[i];
                  return Card(
                    child: ListTile(
                      title: Text('Dispute ${d['id']}'),
                      subtitle: Text('Reason: ${d['reason'] ?? 'N/A'}\nStatus: ${d['status']}'),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        child: const Text('Resolve'),
                        onPressed: () async {
                          final admin = ref.read(authStateChangesProvider).asData?.value;
                          if (admin == null) return;
                          final res = await showDialog<String?>(context: context, builder: (ctx) {
                            final ctrl = TextEditingController();
                            return AlertDialog(title: const Text('Resolution'), content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Resolution note')), actions: [TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save'))]);
                          });
                          if (res != null) {
                            await AdminService(ref.read(firebaseFirestoreProvider)).resolveDispute(d['id'] as String, res, admin.uid);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispute resolved')));
                            await _load();
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