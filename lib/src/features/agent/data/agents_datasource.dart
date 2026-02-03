import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/agent.dart';

class AgentsDataSource {
  final CollectionReference _agents;
  final FirebaseFirestore _firestore;

  AgentsDataSource(this._firestore) : _agents = _firestore.collection('agents');

  Future<Agent?> getAgent(String id) async {
    final snap = await _agents.doc(id).get();
    if (!snap.exists) return null;
    return Agent.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  Future<Agent> ensureAgent(String id) async {
    final a = await getAgent(id);
    if (a != null) return a;
    final agent = Agent(id: id, wallet: 0);
    await _agents.doc(id).set(agent.toMap());
    return agent;
  }

  Future<void> linkBuyer(String agentId, String buyerId) async {
    await _agents.doc(agentId).set({
      'buyers': FieldValue.arrayUnion([buyerId]),
    }, SetOptions(merge: true));
  }

  Future<void> creditCommission(String agentId, int amount) async {
    final ref = _agents.doc(agentId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        tx.set(
          ref,
          Agent(
            id: agentId,
            wallet: amount,
            deliveriesCount: 1,
            totalCommission: amount,
          ).toMap(),
        );
        return;
      }
      final data = Map<String, dynamic>.from(snap.data() as Map);
      final wallet = (data['wallet'] as num?)?.toInt() ?? 0;
      final deliveries = (data['deliveriesCount'] as num?)?.toInt() ?? 0;
      final total = (data['totalCommission'] as num?)?.toInt() ?? 0;
      tx.update(ref, {
        'wallet': wallet + amount,
        'deliveriesCount': deliveries + 1,
        'totalCommission': total + amount,
      });
    });
  }

  Future<List<String>> listBuyers(String agentId) async {
    final snap = await _agents.doc(agentId).get();
    if (!snap.exists) return [];
    final data = Map<String, dynamic>.from(snap.data() as Map);
    return List<String>.from(data['buyers'] ?? []);
  }
}
