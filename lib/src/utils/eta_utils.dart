/// Estimate an ETA range given a distance (km) and speed bounds (km/h).
/// Returns a Map with `earliest` and `latest` DateTime values.
Map<String, DateTime> estimateEtaRange(
  double distanceKm, {
  double minSpeedKmh = 20, // slow end
  double maxSpeedKmh = 45, // fast end
}) {
  if (distanceKm <= 0) {
    final now = DateTime.now();
    return {'earliest': now, 'latest': now};
  }
  final now = DateTime.now();
  final hoursFast = distanceKm / maxSpeedKmh;
  final hoursSlow = distanceKm / minSpeedKmh;
  final earliest = now.add(
    Duration(milliseconds: (hoursFast * 3600 * 1000).round()),
  );
  final latest = now.add(
    Duration(milliseconds: (hoursSlow * 3600 * 1000).round()),
  );
  return {'earliest': earliest, 'latest': latest};
}
