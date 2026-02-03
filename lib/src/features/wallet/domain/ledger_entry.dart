class LedgerEntry {
  final String id;
  final String walletId;
  final int amount; // positive for credit, negative for debit
  final String
  type; // 'pending_credit'|'available_credit'|'withdrawal'|'fee'|'adjustment'
  final String reference; // e.g., orderId
  final DateTime createdAt;

  LedgerEntry({
    required this.id,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.reference,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'walletId': walletId,
    'amount': amount,
    'type': type,
    'reference': reference,
    'createdAt': createdAt.toUtc(),
  };

  factory LedgerEntry.fromMap(Map<String, dynamic> m) => LedgerEntry(
    id: m['id'] as String,
    walletId: m['walletId'] as String,
    amount: (m['amount'] as num).toInt(),
    type: m['type'] as String,
    reference: m['reference'] as String,
    createdAt: (m['createdAt'] is DateTime)
        ? m['createdAt'] as DateTime
        : DateTime.now().toUtc(),
  );
}
