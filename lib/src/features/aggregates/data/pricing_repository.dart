import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/models/pricing.dart';
import 'pricing_datasource.dart';

abstract class PricingRepository {
  Stream<List<Pricing>> watchAll();
  Future<Pricing?> getForProduct(String productId);
  Future<void> setPrice(String productId, double price);
}

class PricingRepositoryImpl implements PricingRepository {
  final PricingDataSource _ds;

  PricingRepositoryImpl(FirebaseFirestore firestore)
    : _ds = PricingDataSource(firestore);

  @override
  Stream<List<Pricing>> watchAll() => _ds.watchAllPricing().map(
    (snap) => snap.docs.map((d) => Pricing.fromMap(d.data())).toList(),
  );

  @override
  Future<Pricing?> getForProduct(String productId) async {
    final data = await _ds.getPricingDoc(productId);
    if (data == null) return null;
    return Pricing.fromMap(data);
  }

  @override
  Future<void> setPrice(String productId, double price) =>
      _ds.setPrice(productId, price);
}
