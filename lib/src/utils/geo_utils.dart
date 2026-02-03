import 'dart:math';

/// Haversine distance between two lat/lng points in kilometers.
double haversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371.0; // km
  final phi1 = _rad(lat1);
  final phi2 = _rad(lat2);
  final dphi = _rad(lat2 - lat1);
  final dlambda = _rad(lon2 - lon1);
  final a =
      (sin(dphi / 2) * sin(dphi / 2)) +
      cos(phi1) * cos(phi2) * (sin(dlambda / 2) * sin(dlambda / 2));
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return r * c;
}

double _rad(double deg) => deg * (pi / 180.0);
