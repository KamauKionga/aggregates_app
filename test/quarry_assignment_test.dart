import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/src/utils/geo_utils.dart';

void main() {
  test('haversine distance prefers closer quarry', () async {
    // Kayole approx (-1.2850, 36.8930)
    final d1 = haversineDistanceKm(-1.2852, 36.8931, -1.2850, 36.8930);
    final d2 = haversineDistanceKm(-1.2852, 36.8931, -1.3000, 36.7800);

    expect(d1 < d2, isTrue);
  });
}
