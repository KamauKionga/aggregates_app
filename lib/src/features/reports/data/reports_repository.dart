import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/report_models.dart';

class ReportsRepository {
  final FirebaseFirestore firestore;
  ReportsRepository(this.firestore);

  Future<Receipt> createReceiptFromOrder(String orderId) async {
    final snap = await firestore.collection('orders').doc(orderId).get();
    if (!snap.exists) throw Exception('Order not found');
    final m = snap.data() as Map<String, dynamic>;
    final id = m['id'] as String? ?? orderId;
    final buyerId = m['buyerId'] as String? ?? '';
    final total = (m['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final createdAt =
        (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final invoice = Map<String, dynamic>.from(m['invoice'] ?? {});
    return Receipt(
      id: id,
      orderId: orderId,
      buyerId: buyerId,
      totalAmount: total,
      createdAt: createdAt,
      invoice: invoice,
    );
  }

  Future<List<AgentReceipt>> getAgentReceipts(
    String agentId,
    DateTime start,
    DateTime end,
  ) async {
    final col = firestore
        .collection('wallets')
        .doc(agentId)
        .collection('ledger');
    final q = await col
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    return q.docs.map((d) {
      final m = d.data();
      return AgentReceipt(
        id: m['id'] as String? ?? d.id,
        agentId: agentId,
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        reference: m['reference'] as String? ?? '',
      );
    }).toList();
  }

  Future<EodReport> generateEodReport(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start
        .add(const Duration(days: 1))
        .subtract(const Duration(milliseconds: 1));

    // Orders created that day
    final ordersQ = await firestore
        .collection('orders')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    int totalOrders = ordersQ.docs.length;
    double totalValue = 0;
    for (final d in ordersQ.docs) {
      final m = d.data();
      totalValue += (m['totalAmount'] as num?)?.toDouble() ?? 0.0;
    }

    // Commissions credited (ledger entries with reference containing 'agent_commission')
    final commissionsQ = await firestore
        .collectionGroup('ledger')
        .where('reference', isGreaterThanOrEqualTo: 'order:')
        .get();
    int totalCommissions = 0;
    for (final d in commissionsQ.docs) {
      final m = d.data();
      final created = (m['createdAt'] as Timestamp?)?.toDate();
      if (created != null && created.isAfter(start) && created.isBefore(end)) {
        final ref = (m['reference'] as String?) ?? '';
        if (ref.contains(':agent_commission') ||
            ref.contains('agent_commission')) {
          totalCommissions += (m['amount'] as num?)?.toInt() ?? 0;
        }
      }
    }

    // Payouts (withdrawals approved that day)
    final withdrawQ = await firestore
        .collection('withdrawals')
        .where('approvedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('approvedAt', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();
    int totalPayouts = 0;
    for (final d in withdrawQ.docs) {
      final m = d.data();
      totalPayouts += (m['amount'] as num?)?.toInt() ?? 0;
    }

    return EodReport(
      date: start,
      totalOrders: totalOrders,
      totalValue: totalValue,
      totalCommissions: totalCommissions,
      totalPayouts: totalPayouts,
    );
  }
}
