# Quarry assignment

Design decisions and implementation:

- Quarry documents are stored in `quarries` collection as:
  - `name` (string)
  - `location` (GeoPoint)
  - `active` (bool)
  - `createdAt` (timestamp)

- Buyers MUST NOT be able to read `quarries` (see `firestore.rules`). Only `admin`, `quarry`, `trucker`, and `agent` roles can read quarries.

- Assignment algorithm:
  - A server-side component (recommended: Cloud Function triggered on `orders` document creation) should call `getNearestQuarry(lat, lng)` and set `assignedQuarryId` on the new order.
  - For convenience, the app includes an `AssignmentService` that can be used by admin UI or server-side code to auto-assign or force-assign a quarry.

- Admin UI:
  - `/admin/assign-quarry` allows admin to seed a Kayole Quarry and reassign order -> quarry.

- Tests:
  - `test/quarry_assignment_test.dart` verifies haversine distance logic.

- Seed data:
  - `seedKayoleIfNotExists()` ensures a `Kayole Junction` quarry exists (lat: -1.2850, lng: 36.8930).

Security and notes:
- To fully enforce server-side auto-assignment and prevent buyers from reading quarry locations, implement the auto-assign logic in a Cloud Function with admin credentials.
- The Firestore rules (`firestore.rules`) block buyers from reading `quarries` and restrict `assignedQuarryId` changes to admins.
