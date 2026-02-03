import 'dart:math';

/// Returns transport cost for distance in kilometers.
/// Rate: 370 Ksh/km, minimum 1,500 Ksh.
double computeTransportCost(double distanceKm) {
  final cost = 370 * distanceKm;
  return max(cost, 1500);
}
