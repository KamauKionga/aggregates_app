class AggregateProduct {
  final String id;
  final String name;
  final String sizeLabel;

  const AggregateProduct({
    required this.id,
    required this.name,
    required this.sizeLabel,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'sizeLabel': sizeLabel,
  };

  factory AggregateProduct.fromMap(Map<String, dynamic> map) =>
      AggregateProduct(
        id: map['id'] as String,
        name: map['name'] as String,
        sizeLabel: map['sizeLabel'] as String,
      );
}
