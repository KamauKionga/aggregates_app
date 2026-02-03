class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final DateTime? createdAt;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'address': address,
    'createdAt': createdAt?.toUtc().toIso8601String(),
  };

  factory LocationModel.fromMap(Map<String, dynamic> map) => LocationModel(
    latitude: (map['latitude'] as num).toDouble(),
    longitude: (map['longitude'] as num).toDouble(),
    address: map['address'] as String? ?? '',
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'] as String).toLocal()
        : null,
  );
}
