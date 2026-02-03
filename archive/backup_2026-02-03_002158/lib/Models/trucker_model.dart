import 'document_model.dart';
import 'truck_model.dart';
import 'driver_model.dart';
import 'enums.dart';

class TruckerModel {
  final String id;
  final String userId; // link to auth user
  String email;
  String phone;
  TruckerType type;
  VerificationStatus verificationStatus;
  List<DocumentModel> documents;
  List<TruckModel> trucks;
  List<DriverModel> drivers;

  // Additional fields: location and policy acceptance
  String? county;
  String? town;
  bool acceptedTerms;
  bool acceptedDataPolicy;

  TruckerModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.phone,
    required this.type,
    this.verificationStatus = VerificationStatus.incomplete,
    this.documents = const [],
    this.trucks = const [],
    this.drivers = const [],
    this.county,
    this.town,
    this.acceptedTerms = false,
    this.acceptedDataPolicy = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'email': email,
        'phone': phone,
        'type': type.toString(),
        'verificationStatus': verificationStatus.toString(),
        'documents': documents.map((d) => d.toMap()).toList(),
        'trucks': trucks.map((t) => t.toMap()).toList(),
        'drivers': drivers.map((d) => d.toMap()).toList(),
        'county': county,
        'town': town,
        'acceptedTerms': acceptedTerms,
        'acceptedDataPolicy': acceptedDataPolicy,
      };

  factory TruckerModel.fromMap(Map<String, dynamic> m) => TruckerModel(
        id: m['id'] as String,
        userId: m['userId'] as String,
        email: m['email'] as String,
        phone: m['phone'] as String,
        type: m['type'].toString().contains('individual')
            ? TruckerType.individual
            : TruckerType.organization,
        verificationStatus:
            m['verificationStatus'].toString().contains('approved')
                ? VerificationStatus.approved
                : m['verificationStatus'].toString().contains('underReview')
                    ? VerificationStatus.underReview
                    : m['verificationStatus'].toString().contains('rejected')
                        ? VerificationStatus.rejected
                        : m['verificationStatus'].toString().contains('submitted')
                            ? VerificationStatus.submitted
                            : VerificationStatus.incomplete,
        documents: ((m['documents'] ?? []) as List)
            .map((e) => DocumentModel.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        trucks: ((m['trucks'] ?? []) as List)
            .map((e) => TruckModel.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        drivers: ((m['drivers'] ?? []) as List)
            .map((e) => DriverModel.fromMap(Map<String, dynamic>.from(e)))
            .toList(),
        county: m['county'] as String?,
        town: m['town'] as String?,
        acceptedTerms: (m['acceptedTerms'] as bool?) ?? false,
        acceptedDataPolicy: (m['acceptedDataPolicy'] as bool?) ?? false,
      );
}
