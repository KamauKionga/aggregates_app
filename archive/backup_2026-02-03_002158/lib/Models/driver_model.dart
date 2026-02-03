class DriverModel {
  final String id;
  String fullName;
  String nationalId;
  String phone;
  String drivingLicense;
  String? psvBadge;
  String? assignedTruckId;

  DriverModel({
    required this.id,
    required this.fullName,
    required this.nationalId,
    required this.phone,
    required this.drivingLicense,
    this.psvBadge,
    this.assignedTruckId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'fullName': fullName,
        'nationalId': nationalId,
        'phone': phone,
        'drivingLicense': drivingLicense,
        'psvBadge': psvBadge,
        'assignedTruckId': assignedTruckId,
      };

  factory DriverModel.fromMap(Map<String, dynamic> m) => DriverModel(
        id: m['id'] as String,
        fullName: m['fullName'] as String,
        nationalId: m['nationalId'] as String,
        phone: m['phone'] as String,
        drivingLicense: m['drivingLicense'] as String,
        psvBadge: m['psvBadge'] as String?,
        assignedTruckId: m['assignedTruckId'] as String?,
      );
}
