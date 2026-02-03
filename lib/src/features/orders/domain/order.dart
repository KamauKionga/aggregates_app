import 'package:cloud_firestore/cloud_firestore.dart';
import '../../payments/domain/payment_method.dart';

/// Current state of an order in the system.
enum OrderStatus {
  created,
  pendingPayment,
  paid,
  loading,
  inTransit,
  outForDelivery,
  delivered,
  cancelled,
}

enum PaymentStatus { pending, paid, failed, refunded }

class Order {
  final String id;
  final String buyerId;
  final Map<String, dynamic> invoice; // e.g., products/prices
  final double goodsAmount;
  final double transportCost;
  final double totalAmount;
  final bool escrow; // true when funds are held by platform
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final OrderStatus status;
  final DateTime createdAt;
  final Map<String, dynamic> timeline;
  final String? paymentReference;
  final String? assignedQuarryId;

  // Trucking fields
  final String? assignedTruckId;
  final String? assignedTruckerId;
  final List<String> proofPhotos; // URLs of POD photos
  final double? distanceKm;
  final DateTime? deliveredAt;
  final int? truckerEarnings;

  Order({
    required this.id,
    required this.buyerId,
    required this.invoice,
    required this.goodsAmount,
    required this.transportCost,
    required this.totalAmount,
    required this.escrow,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdAt,
    this.timeline = const {},
    this.paymentReference,
    this.assignedQuarryId,
    this.assignedTruckId,
    this.assignedTruckerId,
    this.proofPhotos = const [],
    this.distanceKm,
    this.deliveredAt,
    this.truckerEarnings,
  });

  Order copyWith({
    String? id,
    String? buyerId,
    Map<String, dynamic>? invoice,
    double? goodsAmount,
    double? transportCost,
    double? totalAmount,
    bool? escrow,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    OrderStatus? status,
    DateTime? createdAt,
    Map<String, dynamic>? timeline,
    String? paymentReference,
    String? assignedQuarryId,
    String? assignedTruckId,
    String? assignedTruckerId,
    List<String>? proofPhotos,
    double? distanceKm,
    DateTime? deliveredAt,
    int? truckerEarnings,
  }) => Order(
    id: id ?? this.id,
    buyerId: buyerId ?? this.buyerId,
    invoice: invoice ?? this.invoice,
    goodsAmount: goodsAmount ?? this.goodsAmount,
    transportCost: transportCost ?? this.transportCost,
    totalAmount: totalAmount ?? this.totalAmount,
    escrow: escrow ?? this.escrow,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    paymentStatus: paymentStatus ?? this.paymentStatus,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    timeline: timeline ?? this.timeline,
    paymentReference: paymentReference ?? this.paymentReference,
    assignedQuarryId: assignedQuarryId ?? this.assignedQuarryId,
    assignedTruckId: assignedTruckId ?? this.assignedTruckId,
    assignedTruckerId: assignedTruckerId ?? this.assignedTruckerId,
    proofPhotos: proofPhotos ?? this.proofPhotos,
    distanceKm: distanceKm ?? this.distanceKm,
    deliveredAt: deliveredAt ?? this.deliveredAt,
    truckerEarnings: truckerEarnings ?? this.truckerEarnings,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'buyerId': buyerId,
    'invoice': invoice,
    'goodsAmount': goodsAmount,
    'transportCost': transportCost,
    'totalAmount': totalAmount,
    'escrow': escrow,
    'paymentMethod': paymentMethod.name,
    'paymentStatus': paymentStatus.name,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'timeline': timeline,
    'paymentReference': paymentReference,
    'assignedQuarryId': assignedQuarryId,
    'assignedTruckId': assignedTruckId,
    'assignedTruckerId': assignedTruckerId,
    'proofPhotos': proofPhotos,
    'distanceKm': distanceKm,
    'deliveredAt': deliveredAt == null
        ? null
        : Timestamp.fromDate(deliveredAt!),
    'truckerEarnings': truckerEarnings,
  };

  factory Order.fromMap(Map<String, dynamic> m) => Order(
    id: m['id'] as String,
    buyerId: m['buyerId'] as String,
    invoice: Map<String, dynamic>.from(m['invoice'] as Map),
    goodsAmount: (m['goodsAmount'] as num).toDouble(),
    transportCost: (m['transportCost'] as num).toDouble(),
    totalAmount: (m['totalAmount'] as num).toDouble(),
    escrow: m['escrow'] as bool,
    paymentMethod: PaymentMethod.values.firstWhere(
      (e) => e.name == (m['paymentMethod'] as String),
    ),
    paymentStatus: PaymentStatus.values.firstWhere(
      (e) => e.name == (m['paymentStatus'] as String),
    ),
    status: OrderStatus.values.firstWhere(
      (e) => e.name == (m['status'] as String),
    ),
    createdAt: (m['createdAt'] as Timestamp).toDate(),
    timeline: m['timeline'] == null
        ? {}
        : Map<String, dynamic>.from(m['timeline'] as Map),
    paymentReference: m['paymentReference'] as String?,
    assignedQuarryId: m['assignedQuarryId'] as String?,
    assignedTruckId: m['assignedTruckId'] as String?,
    assignedTruckerId: m['assignedTruckerId'] as String?,
    proofPhotos: List<String>.from(m['proofPhotos'] ?? []),
    distanceKm: (m['distanceKm'] as num?)?.toDouble(),
    deliveredAt: m['deliveredAt'] == null
        ? null
        : (m['deliveredAt'] as Timestamp).toDate(),
    truckerEarnings: (m['truckerEarnings'] as num?)?.toInt(),
  );
}
