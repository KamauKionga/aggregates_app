import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_providers.dart';
import '../data/admin_service.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  AdminUsersScreenState createState() => AdminUsersScreenState();
}

class AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _pending = [];

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = AdminService(ref.read(firebaseFirestoreProvider));
    final res = await svc.listPendingAgents();
    setState(() {
      _pending = res;
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
      appBar: AppBar(title: const Text('User Approvals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pending.isEmpty
              ? const Center(child: Text('No pending approvals'))
              : ListView.builder(
                  itemCount: _pending.length,
                  itemBuilder: (c, i) {
                    final u = _pending[i];
                    return Card(
                      child: ListTile(
                        title: Text(u['email'] ?? u['id'] ?? 'Unknown'),
                        subtitle: Text('Role: ${u['role'] ?? 'unknown'}'),
                        trailing: ElevatedButton(
                          child: const Text('Approve'),
                          onPressed: () async {
                            try {
                              final admin = ref.read(authStateChangesProvider).asData?.value;
                              if (admin == null) return;
                              await AdminService(ref.read(firebaseFirestoreProvider)).approveAgent(u['id'] as String, admin.uid);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Approved')));
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