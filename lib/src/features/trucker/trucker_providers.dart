import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'gps_service.dart';

final gpsServiceProvider = Provider<GpsService>((ref) {
  final firestore = FirebaseFirestore.instance;
  return GpsService(firestore: firestore);
});
