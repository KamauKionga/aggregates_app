# Auth feature — Summary

What is included:

- **Auth screens** (minimal, no business logic beyond auth):
  - `SignInScreen` – email/password, phone + OTP, Google, Apple sign-in buttons and flows.
  - `PhoneOtpScreen` – request verification and verify SMS code.
  - `AgentPendingScreen` – UI for agents awaiting approval.

- **Models & schema**:
  - `AppUser` entity (`lib/src/features/auth/domain/entities/app_user.dart`)
  - `UserRole` enum (`lib/src/features/auth/domain/models/user_role.dart`)
  - Firestore schema constants (`lib/src/features/auth/data/firestore_user_schema.dart`)

- **Data & repository**:
  - `FirebaseAuthDataSource` – Firebase Auth + Firestore integration
  - `AuthRepository` (abstract) and `AuthRepositoryImpl`
  - Riverpod providers: `authRepositoryProvider`, `authStateChangesProvider`

- **Routing & guards**:
  - `routerProvider` (GoRouter) in `lib/src/app/routes.dart` performs redirect logic:
    - Unauthenticated users → `/auth/sign-in`
    - Agents without `agentApproved` → `/agent/pending`
    - Authenticated users cannot access `/auth/*`

Notes:
- Agents must sign in with Google; agent accounts are created with `agentApproved=false` and must be toggled by an Admin (via Console or server-side admin panel).
- For Web, ensure `DefaultFirebaseOptions` are generated and passed to `Firebase.initializeApp(options: ...)` as needed.
