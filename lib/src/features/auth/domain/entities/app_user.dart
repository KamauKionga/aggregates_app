import '../models/user_role.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? phoneNumber;
  final String? displayName;
  final UserRole role;
  final bool agentApproved;
  final String? referredByAgentId;

  AppUser({
    required this.uid,
    this.email,
    this.phoneNumber,
    this.displayName,
    required this.role,
    this.agentApproved = false,
    this.referredByAgentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'phoneNumber': phoneNumber,
      'displayName': displayName,
      'role': role.name,
      'agentApproved': agentApproved,
      'referredByAgentId': referredByAgentId,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      email: map['email'] as String?,
      phoneNumber: map['phoneNumber'] as String?,
      displayName: map['displayName'] as String?,
      role: map['role'] != null
          ? UserRoleX.fromString(map['role'] as String)
          : UserRole.buyer,
      agentApproved: map['agentApproved'] as bool? ?? false,
      referredByAgentId: map['referredByAgentId'] as String?,
    );
  }
}
