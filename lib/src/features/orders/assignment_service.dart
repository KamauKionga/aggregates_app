import '../quarry/quarries_repository.dart';
import 'data/orders_datasource.dart';

class AssignmentService {
  final OrdersDataSource _ordersDs;
  final QuarriesRepository _quarriesRepo;

  AssignmentService(this._ordersDs, this._quarriesRepo);

  /// Auto-assigns nearest quarry to the order with id [orderId].
  /// Returns the assigned quarry id or null if none found or order not found.
  Future<String?> autoAssignNearestQuarry(String orderId) async {
    final order = await _ordersDs.getOrder(orderId);
    if (order == null) return null;

    // Expect delivery location stored in invoice as {'deliveryLocation': {'lat': ..., 'lng': ...}}
    final loc = order.invoice['deliveryLocation'] as Map<String, dynamic>?;
    if (loc == null) return null;
    final lat = (loc['lat'] as num).toDouble();
    final lng = (loc['lng'] as num).toDouble();

    final nearest = await _quarriesRepo.getNearestQuarry(lat, lng);
    if (nearest == null) return null;

    // Update order assignedQuarryId (only id stored - we never store quarry coordinates on order so buyers cannot see them)
    await _ordersDs.updateOrder(orderId, {'assignedQuarryId': nearest.id});
    return nearest.id;
  }

  /// Force-assign a quarry (admin action)
  Future<void> forceAssignQuarry(String orderId, String quarryId) async {
    await _ordersDs.updateOrder(orderId, {'assignedQuarryId': quarryId});
  }
}
