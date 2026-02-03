import 'domain/models/aggregate_product.dart';

class AggregatesValidator {
  static const int truckCapacityTons = 14;
  static const List<int> allowedTrucks = [1, 2];

  static bool validateTrucksCount(int trucks) => allowedTrucks.contains(trucks);

  static double computeOrderTons(int trucks) =>
      trucks * truckCapacityTons.toDouble();

  static double computeOrderTotalPrice({
    required double pricePerTon,
    required int trucks,
  }) {
    if (!validateTrucksCount(trucks))
      throw ArgumentError('Trucks must be 1 or 2');
    final tons = computeOrderTons(trucks);
    return tons * pricePerTon;
  }

  static bool validateProductSelection(
    AggregateProduct product,
    List<AggregateProduct> allowed,
  ) {
    return allowed.any((p) => p.id == product.id);
  }
}
