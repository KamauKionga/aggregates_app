import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/src/features/trucker/earnings.dart';

void main() {
  test('computeTruckerEarnings: under min fare', () {
    expect(computeTruckerEarnings(1.0), 1000); // 1km * 250 = 250 -> min 1000
  });

  test('computeTruckerEarnings: exact rate', () {
    expect(computeTruckerEarnings(4.0), 1000); // 4*250=1000
  });

  test('computeTruckerEarnings: larger distance', () {
    expect(computeTruckerEarnings(10.5), 2625); // 10.5*250 = 2625
  });

  test('negative distance throws', () {
    expect(() => computeTruckerEarnings(-1.0), throwsArgumentError);
  });
}
