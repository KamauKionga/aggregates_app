class Order {
  final String id;
  final Map<String, dynamic> invoice;
  String status;
  final DateTime createdAt;
  DateTime? estimatedDelivery;
  final Map<String, String> timeline;
  int? rating;
  String? feedback;
  DateTime? ratedAt;

  Order({
    required this.id,
    required this.invoice,
    required this.status,
    required this.createdAt,
    this.estimatedDelivery,
    Map<String, String>? timeline,
    this.rating,
    this.feedback,
    this.ratedAt,
  }) : timeline = timeline ?? {};

  factory Order.fromMap(Map<String, dynamic> m) => Order(
    id: m['id'] as String,
    invoice: Map<String, dynamic>.from(m['invoice'] as Map),
    status: m['status'] as String,
    createdAt: DateTime.parse(m['createdAt'] as String),
    estimatedDelivery: m['estimatedDelivery'] != null
        ? DateTime.parse(m['estimatedDelivery'] as String)
        : null,
    timeline: m['timeline'] != null
        ? Map<String, String>.from(m['timeline'] as Map)
        : {},
    rating: m['rating'] != null ? (m['rating'] as num).toInt() : null,
    feedback: m['feedback'] as String?,
    ratedAt: m['ratedAt'] != null
        ? DateTime.parse(m['ratedAt'] as String)
        : null,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'invoice': invoice,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'estimatedDelivery': estimatedDelivery?.toIso8601String(),
    'timeline': timeline,
    'rating': rating,
    'feedback': feedback,
    'ratedAt': ratedAt?.toIso8601String(),
  };
}
