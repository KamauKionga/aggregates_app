import 'package:cloud_firestore/cloud_firestore.dart';

class Quarry {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final bool active;
  final DateTime createdAt;

  Quarry({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.active,
    required this.createdAt,
  });

  Quarry copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    bool? active,
    DateTime? createdAt,
  }) => Quarry(
    id: id ?? this.id,
    name: name ?? this.name,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    active: active ?? this.active,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'location': GeoPoint(lat, lng),
    'active': active,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Quarry.fromMap(Map<String, dynamic> m) {
    final gp = m['location'] as GeoPoint;
    return Quarry(
      id: m['id'] as String,
      name: m['name'] as String,
      lat: gp.latitude,
      lng: gp.longitude,
      active: m['active'] as bool? ?? true,
      createdAt: (m['createdAt'] as Timestamp).toDate(),
    );
  }
}
