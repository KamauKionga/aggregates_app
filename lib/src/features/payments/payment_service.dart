import 'domain/payment_method.dart';
import '../orders/domain/order.dart';

abstract class PaymentService {
  /// Initiates payment for [order] using [method]. Optional [details] depend on provider (eg phone for STK).
  Future<PaymentResult> initiatePayment({
    required Order order,
    required PaymentMethod method,
    Map<String, dynamic>? details,
  });
}
