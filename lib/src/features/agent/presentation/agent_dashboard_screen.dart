import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/auth_providers.dart';
import '../../auth/domain/models/user_role.dart';
import '../agents_providers.dart';

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  AgentDashboardScreenState createState() => AgentDashboardScreenState();
}

class AgentDashboardScreenState extends ConsumerState<AgentDashboardScreen> {
  bool _loading = false;
  final _linkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);
    return authState.when(
      data: (user) {
        if (user == null) return const Center(child: Text('Not signed in'));
        if (user.role != UserRole.agent)
          return const Center(child: Text('Not an agent'));
        if (!user.agentApproved)
          return const Center(child: Text('Awaiting admin approval'));

        return FutureBuilder(
          future: _loadAgentInfo(user.uid),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            final data = snap.data as Map<String, dynamic>;
            final agent = data['agent'];
            final buyers = data['buyers'] as List<String>;

            return Scaffold(
              appBar: AppBar(title: const Text('Agent Dashboard')),
              body: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agent: ${user.email ?? user.uid}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          'Wallet: Ksh ${agent?.wallet ?? 0}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        Text('Deliveries: ${agent?.deliveriesCount ?? 0}'),
                        const SizedBox(width: 12),
                        Text(
                          'Total Commission: Ksh ${agent?.totalCommission ?? 0}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Linked Buyers',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: buyers.isEmpty
                          ? const Text('No buyers linked')
                          : ListView.builder(
                              itemCount: buyers.length,
                              itemBuilder: (c, i) =>
                                  ListTile(title: Text(buyers[i])),
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _linkController,
                      decoration: const InputDecoration(
                        labelText: 'Buyer UID or Email to link',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _loading ? null : _linkBuyer,
                          child: _loading
                              ? const CircularProgressIndicator()
                              : const Text('Link Buyer'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Refresh'),
                        ),
                      ],
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

  Future<Map<String, dynamic>> _loadAgentInfo(String uid) async {
    final repo = ref.read(agentsRepositoryProvider);
    final agent = await repo.ensureAgent(uid);
    final buyers = await repo.listBuyers(uid);
    return {'agent': agent, 'buyers': buyers};
  }

  Future<void> _linkBuyer() async {
    final input = _linkController.text.trim();
    if (input.isEmpty) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(agentsRepositoryProvider);
      String? buyerId;
      // Try to resolve email to user id
      final q = await ref
          .read(firebaseFirestoreProvider)
          .collection('users')
          .where('email', isEqualTo: input)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) buyerId = q.docs.first.id;
      // If not found by email, assume input is UID
      buyerId ??= input;
      await repo.linkBuyer(
        agentId: ref.read(authStateChangesProvider).asData!.value!.uid,
        buyerId: buyerId,
      );
      _linkController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Buyer linked')));
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Link failed: ${e.toString()}')));
    } finally {
      setState(() => _loading = false);
    }
  }
}
