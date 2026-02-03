import 'document_model.dart';

class TruckModel {
  final String id;
  String registrationNumber;
  String truckType; // 'Tipper', 'Lorry', 'Semi-Trailer'
  double payloadTons;
  int axles;
  String fuelType;
  int year;
  List<DocumentModel> documents;
  List<String> photos; // urls

  TruckModel({
    required this.id,
    required this.registrationNumber,
    required this.truckType,
    required this.payloadTons,
    required this.axles,
    required this.fuelType,
    required this.year,
    this.documents = const [],
    this.photos = const [],
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'registrationNumber': registrationNumber,
        'truckType': truckType,
        'payloadTons': payloadTons,
        'axles': axles,
        'fuelType': fuelType,
        'year': year,
        'documents': documents.map((d) => d.toMap()).toList(),
        'photos': photos,
      };

  factory TruckModel.fromMap(Map<String, dynamic> m) => TruckModel(
        id: m['id'] as String,
        registrationNumber: m['registrationNumber'] as String,
        truckType: m['truckType'] as String,
        payloadTons: (m['payloadTons'] as num).toDouble(),
        axles: (m['axles'] as num).toInt(),
        fuelType: m['fuelType'] as String,
        year: (m['year'] as num).toInt(),
        documents: ((m['documents'] ?? []) as List)
            .map((e) => DocumentModel.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        photos: List<String>.from(m['photos'] ?? []),
      );
}
