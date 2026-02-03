class Receipt {
  final String id;
  final String orderId;
  final String buyerId;
  final double totalAmount;
  final DateTime createdAt;
  final Map<String, dynamic> invoice;

  Receipt({
    required this.id,
    required this.orderId,
    required this.buyerId,
    required this.totalAmount,
    required this.createdAt,
    required this.invoice,
  });
}

class AgentReceipt {
  final String id;
  final String agentId;
  final int amount; // in Ksh
  final DateTime createdAt;
  final String reference; // e.g., order:<id>

  AgentReceipt({
    required this.id,
    required this.agentId,
    required this.amount,
    required this.createdAt,
    required this.reference,
  });
}

class EodReport {
  final DateTime date;
  final int totalOrders;
  final double totalValue;
  final int totalCommissions;
  final int totalPayouts;

  EodReport({
    required this.date,
    required this.totalOrders,
    required this.totalValue,
    required this.totalCommissions,
    required this.totalPayouts,
  });
}

class CommissionSummary {
  final String agentId;
  final int totalCommission;

  CommissionSummary({required this.agentId, required this.totalCommission});
}

class PayoutSummary {
  final String payoutId;
  final String walletId;
  final int amount;
  final String status;

  PayoutSummary({
    required this.payoutId,
    required this.walletId,
    required this.amount,
    required this.status,
  });
}
