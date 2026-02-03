import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../domain/models/location_model.dart';

/// Simple location save service. Saves the user's last selected location
/// under `users/{uid}/lastLocation` and appends to `users/{uid}/locations` collection.
class LocationSaveService {
  final FirebaseFirestore _firestore;
  final fb.FirebaseAuth _auth;

  LocationSaveService(this._firestore, this._auth);

  Future<void> saveLocation({required LocationModel location}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.set({
      'lastLocation': location.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await userRef.collection('locations').add({
      ...location.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
