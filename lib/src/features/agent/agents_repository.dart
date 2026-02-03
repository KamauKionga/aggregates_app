import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/agents_datasource.dart';
import 'domain/agent.dart';

class AgentsRepository {
  final AgentsDataSource _ds;
  final FirebaseFirestore _firestore;

  AgentsRepository(this._ds, this._firestore);

  Future<Agent?> getAgent(String id) => _ds.getAgent(id);

  Future<Agent> ensureAgent(String id) => _ds.ensureAgent(id);

  Future<void> linkBuyer({
    required String agentId,
    required String buyerId,
  }) async {
    // write to agents collection
    await _ds.linkBuyer(agentId, buyerId);
    // also update buyer user doc to indicate referred agent
    await _firestore.collection('users').doc(buyerId).set({
      'referredByAgentId': agentId,
    }, SetOptions(merge: true));
  }

  Future<void> creditCommission({
    required String agentId,
    required int amount,
  }) async {
    await _ds.creditCommission(agentId, amount);
  }

  Future<List<String>> listBuyers(String agentId) => _ds.listBuyers(agentId);
}
