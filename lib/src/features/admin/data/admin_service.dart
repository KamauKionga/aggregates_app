import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore firestore;
  AdminService(this.firestore);

  Future<List<Map<String, dynamic>>> listPendingAgents() async {
    final q = await firestore.collection('users').where('role', isEqualTo: 'agent').where('agentApproved', isEqualTo: false).get();
    return q.docs.map((d) => Map<String, dynamic>.from(d.data() as Map)).toList();
  }

  Future<void> approveAgent(String agentId, String adminId) async {
    await firestore.collection('users').doc(agentId).set({'agentApproved': true, 'approvedBy': adminId, 'approvedAt': Timestamp.fromDate(DateTime.now())}, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> listWithdrawals({String status = 'requested'}) async {
    final q = await firestore.collection('withdrawals').where('status', isEqualTo: status).get();
    return q.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
  }

  Future<void> approveWithdrawal(String withdrawalId, String adminId) async {
    final withdrawRef = firestore.collection('withdrawals').doc(withdrawalId);
    await firestore.runTransaction((tx) async {
      final snap = await tx.get(withdrawRef);
      if (!snap.exists) throw Exception('Withdrawal not found');
      final data = snap.data() as Map<String, dynamic>;
      if (data['status'] != 'requested') throw Exception('Withdrawal not in requested state');
      final walletRef = firestore.collection('wallets').doc(data['walletId'] as String);
      final wSnap = await tx.get(walletRef);
      if (!wSnap.exists) throw Exception('Wallet missing');
      final wData = wSnap.data() as Map<String, dynamic>;
      final available = (wData['available'] as num?)?.toInt() ?? 0;
      final amount = (data['amount'] as num).toInt();
      if (available < amount) throw Exception('Insufficient wallet balance');
      tx.update(walletRef, {'available': available - amount, 'updatedAt': Timestamp.fromDate(DateTime.now())});
      tx.update(withdrawRef, {'status': 'approved', 'approvedBy': adminId, 'approvedAt': Timestamp.fromDate(DateTime.now())});
      final ledgerRef = walletRef.collection('ledger').doc();
      tx.set(ledgerRef, {'id': ledgerRef.id, 'walletId': walletRef.id, 'amount': -amount, 'type': 'withdrawal', 'reference': withdrawalId, 'createdAt': Timestamp.fromDate(DateTime.now())});
    });
  }

  Future<List<Map<String, dynamic>>> listDisputes({String status = 'open'}) async {
    final q = await firestore.collection('disputes').where('status', isEqualTo: status).get();
    return q.docs.map((d) => Map<String, dynamic>.from(d.data())).toList();
  }

  Future<void> resolveDispute(String disputeId, String resolution, String resolverId) async {
    await firestore.collection('disputes').doc(disputeId).set({'status': 'resolved', 'resolution': resolution, 'resolvedBy': resolverId, 'resolvedAt': Timestamp.fromDate(DateTime.now())}, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getAnalyticsOverview() async {
    // simple aggregations
    final usersQ = await firestore.collection('users').get();
    final ordersQ = await firestore.collection('orders').get();
    final withdrawQ = await firestore.collection('withdrawals').where('status', isEqualTo: 'requested').get();

    int totalUsers = usersQ.docs.length;
    int totalOrders = ordersQ.docs.length;
    int pendingWithdrawals = withdrawQ.docs.length;

    // sum wallets available
    final walletsQ = await firestore.collection('wallets').get();
    int totalWallet = 0;
    for (final d in walletsQ.docs) {
      final m = d.data();
      totalWallet += (m['available'] as num?)?.toInt() ?? 0;
    }

    return {
      'totalUsers': totalUsers,
      'totalOrders': totalOrders,
      'pendingWithdrawals': pendingWithdrawals,
      'totalWalletBalance': totalWallet,
    };
  }
}