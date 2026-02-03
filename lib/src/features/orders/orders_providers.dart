import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../orders/data/orders_datasource.dart';
import '../orders/data/orders_repository.dart';
import 'domain/order.dart' as ord;
import '../payments/payment_service.dart';
import '../payments/payment_service_impl.dart';
import '../auth/auth_providers.dart' show firebaseFirestoreProvider;
import '../quarry/quarries_providers.dart' show quarriesRepositoryProvider;
import '../orders/assignment_service.dart' show AssignmentService;

final ordersDataSourceProvider = Provider.autoDispose<OrdersDataSource>(
  (ref) => OrdersDataSource(ref.read(firebaseFirestoreProvider)),
);

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepositoryImpl(
    ref.read(ordersDataSourceProvider),
    ref.read(paymentServiceProvider),
  ),
);

final paymentServiceProvider = Provider<PaymentService>(
  (_) => MockPaymentService(),
);

final assignmentServiceProvider = Provider.autoDispose(
  (ref) => AssignmentService(
    ref.read(ordersDataSourceProvider),
    ref.read(quarriesRepositoryProvider),
  ),
);

// Stream provider for watching a single order
final orderStreamProvider = StreamProvider.family<ord.Order, String>(
  (ref, orderId) => ref.read(ordersRepositoryProvider).watchOrder(orderId),
);

// Future provider for a user's order history
final userOrdersProvider = FutureProvider.family<List<ord.Order>, String>(
  (ref, userId) => ref.read(ordersRepositoryProvider).getOrdersForUser(userId),
);
