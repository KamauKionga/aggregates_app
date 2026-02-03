import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'domain/models/aggregate_product.dart';
import 'data/pricing_repository.dart';
import 'domain/models/pricing.dart';

// Default products
final defaultAggregateProductsProvider = Provider<List<AggregateProduct>>(
  (_) => const [
    AggregateProduct(id: 'dust', name: 'Dust', sizeLabel: 'Dust'),
    AggregateProduct(id: 'quarter', name: '1/4"', sizeLabel: '1/4"'),
    AggregateProduct(id: 'half', name: '1/2"', sizeLabel: '1/2"'),
    AggregateProduct(id: 'threequarter', name: '3/4"', sizeLabel: '3/4"'),
    AggregateProduct(id: 'one', name: '1"', sizeLabel: '1"'),
    AggregateProduct(id: 'ballast', name: 'Ballast', sizeLabel: 'Ballast'),
  ],
);

final pricingRepositoryProvider = Provider<PricingRepository>(
  (ref) => PricingRepositoryImpl(FirebaseFirestore.instance),
);

final pricingListStreamProvider = StreamProvider<List<Pricing>>((ref) {
  return ref.read(pricingRepositoryProvider).watchAll();
});

// Helper to get price for a product, returns default 1100 if not set
final priceForProductProvider = FutureProvider.family<double, String>((
  ref,
  productId,
) async {
  final repo = ref.read(pricingRepositoryProvider);
  final p = await repo.getForProduct(productId);
  return p?.pricePerTon ?? 1100.0; // default Ksh/ton
});
