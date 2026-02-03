import 'domain/payment_method.dart';
import 'payment_service.dart';
import '../orders/domain/order.dart';

/// Mock implementation that simulates payment providers. Replace with real provider integration later.
class MockPaymentService implements PaymentService {
  @override
  Future<PaymentResult> initiatePayment({
    required Order order,
    required PaymentMethod method,
    Map<String, dynamic>? details,
  }) async {
    // Basic validation
    if (method == PaymentMethod.mpesa) {
      final phone = details?['phone'] as String?;
      if (phone == null || phone.isEmpty) {
        return PaymentResult(
          success: false,
          message: 'Missing phone for MPESA STK',
        );
      }
      // Simulate STK push (we return success immediately in mock)
      final ref = 'MPESA-STK-${DateTime.now().millisecondsSinceEpoch}';
      // In real impl this might be pending until user accepts STK, so we could return pending=true
      return PaymentResult(
        success: true,
        reference: ref,
        message: 'MPESA STK simulated',
      );
    }

    if (method == PaymentMethod.card) {
      // expecting token/details in details
      final token = details?['token'] as String?;
      if (token == null)
        return PaymentResult(success: false, message: 'Missing card token');
      final ref = 'CARD-${DateTime.now().millisecondsSinceEpoch}';
      return PaymentResult(
        success: true,
        reference: ref,
        message: 'Card payment simulated',
      );
    }

    if (method == PaymentMethod.bank) {
      final acc = details?['account'] as String?;
      if (acc == null)
        return PaymentResult(success: false, message: 'Missing bank account');
      final ref = 'BANK-${DateTime.now().millisecondsSinceEpoch}';
      return PaymentResult(
        success: true,
        reference: ref,
        message: 'Bank transfer simulated',
      );
    }

    return PaymentResult(success: false, message: 'Unsupported method');
  }
}
