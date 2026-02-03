import 'domain/quarry.dart';
import 'data/quarries_datasource.dart';
import '../../utils/geo_utils.dart';

class QuarriesRepository {
  final QuarriesDataSource _ds;

  QuarriesRepository(this._ds);

  Future<List<Quarry>> getAllActiveQuarries() => _ds.getAllQuarries();

  Future<Quarry?> getQuarryById(String id) => _ds.getQuarryById(id);

  Future<Quarry> createQuarry({
    required String name,
    required double lat,
    required double lng,
  }) => _ds.createQuarry(name: name, lat: lat, lng: lng);

  Future<void> updateQuarry(String id, Map<String, dynamic> patch) =>
      _ds.updateQuarry(id, patch);

  /// Seed a sample quarry at Kayole Junction (lat/lng approximate). Useful for local dev and tests.
  Future<Quarry> seedKayoleIfNotExists() async {
    final qs = await _ds.getAllQuarries();
    final exists = qs.any((q) => q.name.toLowerCase().contains('kayole'));
    if (exists)
      return qs.firstWhere((q) => q.name.toLowerCase().contains('kayole'));
    return await _ds.createQuarry(
      name: 'Kayole Junction',
      lat: -1.2850,
      lng: 36.8930,
    );
  }

  /// Find nearest active quarry to (lat,lng). Returns null if no active quarries.
  Future<Quarry?> getNearestQuarry(double lat, double lng) async {
    final qs = await _ds.getAllQuarries();
    if (qs.isEmpty) return null;
    Quarry? best;
    double bestDist = double.infinity;
    for (final q in qs) {
      final d = haversineDistanceKm(lat, lng, q.lat, q.lng);
      if (d < bestDist) {
        bestDist = d;
        best = q;
      }
    }
    return best;
  }
}
