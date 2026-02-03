class Pricing {
  final String productId;
  final double pricePerTon; // in Ksh
  final DateTime? updatedAt;

  Pricing({required this.productId, required this.pricePerTon, this.updatedAt});

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'pricePerTon': pricePerTon,
    'updatedAt': updatedAt?.toUtc().toIso8601String(),
  };

  factory Pricing.fromMap(Map<String, dynamic> map) => Pricing(
    productId: map['productId'] as String,
    pricePerTon: (map['pricePerTon'] as num).toDouble(),
    updatedAt: map['updatedAt'] != null
        ? DateTime.parse(map['updatedAt'] as String).toLocal()
        : null,
  );
}
