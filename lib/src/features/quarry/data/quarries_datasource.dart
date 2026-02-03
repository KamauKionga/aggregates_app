import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/quarry.dart';

class QuarriesDataSource {
  final CollectionReference _col;

  QuarriesDataSource(FirebaseFirestore firestore)
    : _col = firestore.collection('quarries');

  Future<List<Quarry>> getAllQuarries() async {
    final snap = await _col.where('active', isEqualTo: true).get();
    return snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data() as Map);
      m['id'] = d.id;
      return Quarry.fromMap(m);
    }).toList();
  }

  Future<Quarry?> getQuarryById(String id) async {
    final snap = await _col.doc(id).get();
    if (!snap.exists) return null;
    final m = Map<String, dynamic>.from(snap.data() as Map);
    m['id'] = snap.id;
    return Quarry.fromMap(m);
  }

  Future<Quarry> createQuarry({
    required String name,
    required double lat,
    required double lng,
    bool active = true,
  }) async {
    final id = _col.doc().id;
    final q = Quarry(
      id: id,
      name: name,
      lat: lat,
      lng: lng,
      active: active,
      createdAt: DateTime.now(),
    );
    await _col.doc(id).set(q.toMap());
    return q;
  }

  Future<void> updateQuarry(String id, Map<String, dynamic> patch) async {
    await _col.doc(id).set(patch, SetOptions(merge: true));
  }
}
