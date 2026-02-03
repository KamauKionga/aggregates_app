import 'package:cloud_firestore/cloud_firestore.dart';

const String pricingCollection = 'aggregates_pricing';

class PricingDataSource {
  final FirebaseFirestore _firestore;
  PricingDataSource(this._firestore);

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllPricing() {
    return _firestore.collection(pricingCollection).snapshots();
  }

  Future<Map<String, dynamic>?> getPricingDoc(String productId) async {
    final doc = await _firestore
        .collection(pricingCollection)
        .doc(productId)
        .get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> setPrice(String productId, double price) async {
    await _firestore.collection(pricingCollection).doc(productId).set({
      'productId': productId,
      'pricePerTon': price,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
