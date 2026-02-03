import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/location_permission_service.dart';
import 'services/location_save_service.dart';

final locationPermissionServiceProvider = Provider<LocationPermissionService>(
  (_) => LocationPermissionService(),
);
final firebaseFirestoreForLocationProvider = Provider<FirebaseFirestore>(
  (_) => FirebaseFirestore.instance,
);
final firebaseAuthProviderForLocation = Provider<FirebaseAuth>(
  (_) => FirebaseAuth.instance,
);
final locationSaveServiceProvider = Provider<LocationSaveService>((ref) {
  return LocationSaveService(
    ref.read(firebaseFirestoreForLocationProvider),
    ref.read(firebaseAuthProviderForLocation),
  );
});
