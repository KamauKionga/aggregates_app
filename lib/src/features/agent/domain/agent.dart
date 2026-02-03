class Agent {
  final String id; // same as AppUser uid
  final int wallet; // stored in Ksh
  final List<String> buyers; // linked buyer UIDs
  final int commissionPerTruck;
  final int deliveriesCount;
  final int totalCommission;

  Agent({
    required this.id,
    required this.wallet,
    this.buyers = const [],
    this.commissionPerTruck = 200,
    this.deliveriesCount = 0,
    this.totalCommission = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'wallet': wallet,
    'buyers': buyers,
    'commissionPerTruck': commissionPerTruck,
    'deliveriesCount': deliveriesCount,
    'totalCommission': totalCommission,
  };

  factory Agent.fromMap(Map<String, dynamic> m) => Agent(
    id: m['id'] as String,
    wallet: (m['wallet'] as num?)?.toInt() ?? 0,
    buyers: List<String>.from(m['buyers'] ?? []),
    commissionPerTruck: (m['commissionPerTruck'] as num?)?.toInt() ?? 200,
    deliveriesCount: (m['deliveriesCount'] as num?)?.toInt() ?? 0,
    totalCommission: (m['totalCommission'] as num?)?.toInt() ?? 0,
  );
}
