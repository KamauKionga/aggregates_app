int computeTruckerEarnings(
  double distanceKm, {
  int ratePerKm = 250,
  int minFare = 1000,
}) {
  if (distanceKm < 0) throw ArgumentError('distanceKm must be >= 0');
  final amt = (distanceKm * ratePerKm).round();
  return amt < minFare ? minFare : amt;
}
