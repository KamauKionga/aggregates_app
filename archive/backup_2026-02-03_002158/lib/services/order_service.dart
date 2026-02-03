import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/order.dart';
import 'app_settings.dart';

class OrderService {
  static const _key = 'orders_v1';

  static Future<List<Order>> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Order.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<Order> orders) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(orders.map((o) => o.toMap()).toList());
    await prefs.setString(_key, raw);
  }

  static Future<Order> createOrder(Map<String, dynamic> invoice) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final createdAt = DateTime.now();

    // estimate delivery time
    final settings = await AppSettings.load();
    final distance = (invoice['distanceKm'] ?? 0.0) as double;
    final numTrucks = (invoice['numTrucks'] ?? 1) as int;
    final available = (settings.prices.isNotEmpty)
        ? 3
        : 3; // default 3, Admin can be updated later

    const avgSpeedKmh = 40.0;
    final transportHours = distance / avgSpeedKmh;
    final loadingHours = 1.0; // default; could be from settings later
    final trips = (numTrucks / available).ceil();
    final totalHours = trips * (loadingHours + transportHours);

    final est = createdAt.add(Duration(minutes: (totalHours * 60).ceil()));

    final order = Order(
      id: id,
      invoice: invoice,
      status: 'Scheduled',
      createdAt: createdAt,
      estimatedDelivery: est,
      timeline: {'Scheduled': createdAt.toIso8601String()},
    );

    final all = await _loadAll();
    all.add(order);
    await _saveAll(all);

    // Simulate progression in background (timers won't survive app restart)
    _simulateProgress(order);

    return order;
  }

  static Future<List<Order>> getOrders() async => await _loadAll();

  static Future<List<Order>> getUndeliveredOrders() async {
    final all = await _loadAll();
    return all.where((o) => o.status.toLowerCase() != 'delivered').toList();
  }

  static Future<Order?> getOrder(String id) async {
    final all = await _loadAll();
    for (final o in all) {
      if (o.id == id) return o;
    }
    return null;
  }

  static Future<void> updateStatus(String id, String status) async {
    final all = await _loadAll();
    final idx = all.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    all[idx].status = status;
    all[idx].timeline[status] = DateTime.now().toIso8601String();
    await _saveAll(all);
  }

  static Future<void> addRating(String id, int rating, String? feedback) async {
    final all = await _loadAll();
    final idx = all.indexWhere((o) => o.id == id);
    if (idx == -1) return;
    all[idx].rating = rating;
    all[idx].feedback = feedback;
    all[idx].ratedAt = DateTime.now();
    await _saveAll(all);
  }

  static void _simulateProgress(Order order) {
    // Advance to Loading after 10s, InTransit after 20s, OutForDelivery after 30s, Delivered after 40s
    Future.delayed(
      const Duration(seconds: 10),
      () => updateStatus(order.id, 'Loading'),
    );
    Future.delayed(
      const Duration(seconds: 20),
      () => updateStatus(order.id, 'In Transit'),
    );
    Future.delayed(
      const Duration(seconds: 30),
      () => updateStatus(order.id, 'Out for Delivery'),
    );
    Future.delayed(
      const Duration(seconds: 40),
      () => updateStatus(order.id, 'Delivered'),
    );
  }
}
