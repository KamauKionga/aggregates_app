class Wallet {
  final String id; // owner id (user/quarry/trucker/platform)
  final String ownerType; // 'trucker'|'agent'|'quarry'|'platform'
  final int available; // available for withdrawal
  final int pending; // locked until EoD
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.ownerType,
    required this.available,
    required this.pending,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'ownerType': ownerType,
    'available': available,
    'pending': pending,
    'updatedAt': updatedAt.toUtc(),
  };

  factory Wallet.fromMap(Map<String, dynamic> m) => Wallet(
    id: m['id'] as String,
    ownerType: m['ownerType'] as String,
    available: (m['available'] as num?)?.toInt() ?? 0,
    pending: (m['pending'] as num?)?.toInt() ?? 0,
    updatedAt: (m['updatedAt'] is DateTime)
        ? m['updatedAt'] as DateTime
        : DateTime.now().toUtc(),
  );
}
