enum PaymentMethod { mpesa, card, bank }

class PaymentResult {
  final bool success;
  final String? reference;
  final String? message;
  final bool pending; // some methods (STK) may be pending until user completes

  PaymentResult({
    required this.success,
    this.reference,
    this.message,
    this.pending = false,
  });
}
