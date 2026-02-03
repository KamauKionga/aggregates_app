import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/src/features/orders/utils/transport_pricing.dart';

void main() {
  test('transport pricing minimum', () {
    final cost = computeTransportCost(1.0); // 370 < 1500 -> min applies
    expect(cost, 1500);
  });

  test('transport pricing proportional', () {
    final cost = computeTransportCost(10.0); // 370*10 = 3700
    expect(cost, 3700);
  });
}
