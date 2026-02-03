import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../domain/order.dart';

class OrdersDataSource {
  final CollectionReference _orders;

  OrdersDataSource(FirebaseFirestore firestore)
    : _orders = firestore.collection('orders');

  Future<Order> createOrder(Order order) async {
    final id = _orders.doc().id;
    final withId = order.copyWith(id: id);
    await _orders.doc(id).set(withId.toMap());
    final snap = await _orders.doc(id).get();
    return Order.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  Future<Order?> getOrder(String id) async {
    final snap = await _orders.doc(id).get();
    if (!snap.exists) return null;
    return Order.fromMap(Map<String, dynamic>.from(snap.data() as Map));
  }

  Stream<Order> orderStream(String id) => _orders
      .doc(id)
      .snapshots()
      .map((s) => Order.fromMap(Map<String, dynamic>.from(s.data() as Map)));

  Future<void> updateOrder(String id, Map<String, dynamic> patch) async {
    await _orders.doc(id).set(patch, SetOptions(merge: true));
  }

  Future<List<Order>> getOrdersForUser(String userId) async {
    final q = await _orders.where('buyerId', isEqualTo: userId).get();
    return q.docs
        .map((d) => Order.fromMap(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }

  Future<List<Order>> getUndeliveredOrders() async {
    // We treat anything not delivered or cancelled as active
    final q = await _orders.where('status', isNotEqualTo: 'delivered').get();
    return q.docs
        .map((d) => Order.fromMap(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }

  Future<Order?> getActiveOrderForTruck(String truckId) async {
    final q = await _orders
        .where('assignedTruckId', isEqualTo: truckId)
        .where('status', isNotEqualTo: 'delivered')
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return Order.fromMap(Map<String, dynamic>.from(q.docs.first.data() as Map));
  }

  Future<List<Order>> getOrdersForTrucker(String truckerId) async {
    final q = await _orders
        .where('assignedTruckerId', isEqualTo: truckerId)
        .get();
    return q.docs
        .map((d) => Order.fromMap(Map<String, dynamic>.from(d.data() as Map)))
        .toList();
  }
}
