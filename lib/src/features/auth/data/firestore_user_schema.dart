/// Firestore user document schema for `users/{uid}` collection.
///
/// Fields:
/// - uid: string (document id, optional inside fields)
/// - email: string | null
/// - phoneNumber: string | null
/// - displayName: string | null
/// - role: string enum (buyer|agent|trucker|quarry|admin)
/// - agentApproved: bool (for agent role, default false)
/// - createdAt: Timestamp
/// - updatedAt: Timestamp

const String usersCollection = 'users';

class UserFields {
  static const uid = 'uid';
  static const email = 'email';
  static const phoneNumber = 'phoneNumber';
  static const displayName = 'displayName';
  static const role = 'role';
  static const agentApproved = 'agentApproved';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
}
