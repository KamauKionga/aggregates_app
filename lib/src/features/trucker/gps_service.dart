import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Simple GPS tracking service for truckers. Streams device position and writes
/// the latest position to Firestore under `truck_locations/{truckId}`.
class GpsService {
  final FirebaseFirestore firestore;
  StreamSubscription<Position>? _sub;
  String? _truckId;

  GpsService({required this.firestore});

  Stream<Position> positionStream({LocationSettings? settings}) {
    return Geolocator.getPositionStream(
      locationSettings: settings ?? const LocationSettings(),
    ).map((p) => p);
  }

  Future<void> startTracking({required String truckId}) async {
    _truckId = truckId;

    // Ensure permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied ||
          req == LocationPermission.deniedForever) {
        throw Exception('Location permission denied');
      }
    }

    _sub?.cancel();
    _sub = Geolocator.getPositionStream().listen((pos) async {
      if (_truckId == null) return;
      await firestore.collection('truck_locations').doc(_truckId).set({
        'lat': pos.latitude,
        'lng': pos.longitude,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    });
  }

  Future<void> stopTracking() async {
    await _sub?.cancel();
    _sub = null;
    _truckId = null;
  }

  bool get isTracking => _sub != null;
}
