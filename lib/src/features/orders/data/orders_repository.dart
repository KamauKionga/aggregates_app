import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../../payments/payment_service.dart';
import '../../payments/domain/payment_method.dart' as pm;
import 'orders_datasource.dart';
import '../domain/order.dart';
import '../../trucker/earnings.dart';

abstract class OrdersRepository {
  Future<Order> createOrder({
    required String buyerId,
    required Map<String, dynamic> invoice,
    required double goodsAmount,
    required double transportCost,
    required pm.PaymentMethod paymentMethod,
  });

  /// Initiate payment for an order and update order record based on result.
  Future<void> payOrder(
    String orderId,
    pm.PaymentMethod method, {
    Map<String, dynamic>? details,
  });

  Stream<Order> watchOrder(String orderId);

  Future<List<Order>> getOrdersForUser(String userId);

  /// List orders assigned to a trucker
  Future<List<Order>> getOrdersForTrucker(String truckerId);

  Future<List<Order>> getUndeliveredOrders();

  Future<void> updateOrderStatus(String orderId, OrderStatus status);

  /// Assign a quarry to an order (admin/service action)
  Future<void> assignQuarry(String orderId, String quarryId);

  /// Assign a truck (and trucker) to an order. Throws if truck already has an active order.
  Future<void> assignTruckToOrder({
    required String orderId,
    required String truckId,
    required String truckerId,
  });

  /// Get any active order for a given truck.
  Future<Order?> getActiveOrderForTruck(String truckId);

  /// Deliver an order: attach proof photos, distance and finalize delivery (releases escrow).
  Future<void> deliverOrder({
    required String orderId,
    required double distanceKm,
    required List<String> proofPhotoUrls,
  });
}

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersDataSource _ds;
  final PaymentService _payments;

  OrdersRepositoryImpl(this._ds, this._payments);

  @override
  Future<Order> createOrder({
    required String buyerId,
    required Map<String, dynamic> invoice,
    required double goodsAmount,
    required double transportCost,
    required pm.PaymentMethod paymentMethod,
  }) async {
    final total = goodsAmount + transportCost;
    final order = Order(
      id: '',
      buyerId: buyerId,
      invoice: invoice,
      goodsAmount: goodsAmount,
      transportCost: transportCost,
      totalAmount: total,
      escrow: false,
      paymentMethod: paymentMethod,
      paymentStatus: PaymentStatus.pending,
      status: OrderStatus.pendingPayment,
      createdAt: DateTime.now(),
    );

    return await _ds.createOrder(order);
  }

  @override
  Future<void> payOrder(
    String orderId,
    pm.PaymentMethod method, {
    Map<String, dynamic>? details,
  }) async {
    final order = await _ds.getOrder(orderId);
    if (order == null) throw Exception('Order not found');

    // Initiate payment via payment service
    final res = await _payments.initiatePayment(
      order: order,
      method: method,
      details: details ?? {},
    );

    if (res.success) {
      // Mark as paid and place funds in escrow until delivery
      await _ds.updateOrder(orderId, {
        'paymentStatus': 'paid',
        'escrow': true,
        'status': 'paid',
        'paymentReference': res.reference,
        'timeline.paidAt': Timestamp.fromDate(DateTime.now()),
      });
    } else {
      await _ds.updateOrder(orderId, {'paymentStatus': 'failed'});
      throw Exception('Payment failed: ${res.message ?? 'unknown'}');
    }
  }

  @override
  Stream<Order> watchOrder(String orderId) => _ds.orderStream(orderId);

  @override
  Future<List<Order>> getOrdersForUser(String userId) =>
      _ds.getOrdersForUser(userId);

  @override
  Future<List<Order>> getOrdersForTrucker(String truckerId) =>
      _ds.getOrdersForTrucker(truckerId);

  @override
  Future<List<Order>> getUndeliveredOrders() => _ds.getUndeliveredOrders();

  @override
  Future<void> assignQuarry(String orderId, String quarryId) async {
    await _ds.updateOrder(orderId, {
      'assignedQuarryId': quarryId,
      'timeline.assignedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> assignTruckToOrder({
    required String orderId,
    required String truckId,
    required String truckerId,
  }) async {
    // Enforce single active order per truck
    final active = await _ds.getActiveOrderForTruck(truckId);
    if (active != null) throw Exception('Truck is already on an active order');

    await _ds.updateOrder(orderId, {
      'assignedTruckId': truckId,
      'assignedTruckerId': truckerId,
      'timeline.truckAssignedAt': Timestamp.fromDate(DateTime.now()),
      'status': OrderStatus.outForDelivery.name,
    });
  }

  @override
  Future<Order?> getActiveOrderForTruck(String truckId) =>
      _ds.getActiveOrderForTruck(truckId);

  @override
  Future<void> deliverOrder({
    required String orderId,
    required double distanceKm,
    required List<String> proofPhotoUrls,
  }) async {
    final earnings = computeTruckerEarnings(distanceKm);

    await _ds.updateOrder(orderId, {
      'status': OrderStatus.delivered.name,
      'distanceKm': distanceKm,
      'proofPhotos': proofPhotoUrls,
      'truckerEarnings': earnings,
      'deliveredAt': Timestamp.fromDate(DateTime.now()),
      'timeline.deliveredAt': Timestamp.fromDate(DateTime.now()),
      'escrow': false,
      'timeline.released': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _ds.updateOrder(orderId, {
      'status': status.name,
      'timeline.${status.name}': Timestamp.fromDate(DateTime.now()),
    });

    // If delivered and escrow is true, release escrow (business logic: platform release) - simple approach
    if (status == OrderStatus.delivered) {
      await _ds.updateOrder(orderId, {
        'escrow': false,
        'timeline.released': Timestamp.fromDate(DateTime.now()),
      });
    }
  }
}
