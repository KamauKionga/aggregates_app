# Firestore User Schema

We use a `users` collection with one document per user: `users/{uid}`.

Fields:
- `uid` (string): user id (document id) 
- `email` (string | null)
- `phoneNumber` (string | null)
- `displayName` (string | null)
- `role` (string): one of `buyer`, `agent`, `trucker`, `quarry`, `admin`
- `agentApproved` (bool): only meaningful for `agent` role. Defaults to `false` on initial sign up. Admins toggle to `true` when approving.
- `createdAt` / `updatedAt` (Timestamp): metadata

Security rules (high level guidance):
- Only authenticated users may read their own user document.
- Admins can update any user's `agentApproved` and `role` fields.
- Clients should not be able to escalate their role to `admin`.
- Validate `role` values against the defined enum.

Example rule snippet (Firestore rules):

match /databases/{database}/documents {
  match /users/{userId} {
    allow read: if request.auth != null && request.auth.uid == userId;
    allow create: if request.auth != null && request.auth.uid == userId;
    allow update: if request.auth != null && (
      request.auth.token.admin == true || // custom claim
      request.auth.uid == userId // allow users to update limited profile fields
    );
  }
}
