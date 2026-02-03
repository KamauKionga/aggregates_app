# Copilot / AI agent instructions for aggregates_app

Purpose
- Short: help AI agents become productive immediately in this Flutter app.
- Focus: architecture, key integration points, developer workflows, and project-specific conventions.

Big picture (1–2 lines)
- This is a small, single-package Flutter app that uses Firebase Auth for authentication, SharedPreferences as a lightweight local store for app data, and a simple service layer under `lib/services/` to encapsulate app logic.

Project structure (what to read first)
- Entry: `lib/main.dart` — initializes Firebase and launches `LandingScreen`.
- UI: `lib/screens/` — each screen is a small widget (e.g., `signup_screen.dart`, `email_verification_screen.dart`, `buyer_order_screen.dart`).
- Services: `lib/services/` — business logic and persistence: `auth_service.dart`, `order_service.dart`, `chat_service.dart`, `app_settings.dart`.
- Models: `lib/Models/` — domain objects (note: directory name capitalized as `Models`).
- Tests: `test/` contains widget tests (e.g., `buyer_flow_test.dart`).

Key conventions & patterns (explicit & discoverable)
- Local persistence uses `SharedPreferences` for simple storage; keys are versioned strings (e.g., `orders_v1`, `app_settings_v1`, `chat_messages_v1`). Update keys if you change the structure.
- Auth flows live in `AuthService` (`lib/services/auth_service.dart`):
  - Email/password and email-link sign-in are implemented. Email link flow stores the sending email under SharedPreferences key `email_for_sign_in` (see `sendSignInLinkToEmail`).
  - Google sign-in uses `GoogleAuthProvider()` and `FirebaseAuth.signInWithProvider(...)` — ensure native platform config is set.
- Order flow simulates background state transitions (see `_simulateProgress` in `OrderService`) with sequential delayed timers (10s, 20s, 30s, 40s) — useful for deterministic tests and local dev. Note timers do NOT survive app restarts.
- UI testability: many widgets expose `ValueKey` keys (e.g., `ValueKey('role_Buyer')`, `ValueKey('tonnage')`, `ValueKey('pay_mpesa')`) — use these in tests and agent-generated widget tests.
- Firebase config: platform config files are present (`android/app/google-services.json`, `lib/firebase_options.dart`). Dynamic links are hinted in `main.dart`; enabling automatic email-link handling also requires `firebase_dynamic_links` and native Firebase setup.

Build / test / debugging commands (concrete)
- Install deps: `flutter pub get`
- Run app: `flutter run` (or `flutter run -d <device>`)
- Analyze: `flutter analyze`
- Run tests: `flutter test` or `flutter test test/buyer_flow_test.dart`
- Format: `dart format .` or `flutter format .`
- Android build/debug: use gradle wrapper in `android/` (`.
gr
adlew.bat assembleDebug` on Windows or `flutter build apk`).

Platform & integration notes
- Firebase: `Firebase.initializeApp` is called with `DefaultFirebaseOptions` in `main.dart`. If you change Firebase projects or dynamic-link behavior, update `lib/firebase_options.dart` and call out changes to `ActionCodeSettings.url`.
- Google sign-in: requires enabling the provider in Firebase console and configuring SHA keys, reverse client IDs on iOS, or correct package names / bundle ids.
- Maps & location: `google_maps_flutter`, `geolocator`, `geocoding` are included; platform permissions and API keys are required.

Testing & CI cues
- Tests are simple widget tests using `flutter_test`. Use `pumpAndSettle()` to allow service loads (`AppSettings.load()`) and simulated timers.
- No GitHub Actions workflow exists in this repo — if you add CI, run `flutter analyze`, `dart format --set-exit-if-changed .`, and `flutter test`.

Files to reference for specific behaviors
- Auth flows: `lib/services/auth_service.dart` and email flow hooks in `lib/screens/signup_screen.dart` and `lib/screens/email_verification_screen.dart`.
- Order behavior + persistence + simulated progress: `lib/services/order_service.dart`.
- Local app settings format & persistence: `lib/services/app_settings.dart` (key `app_settings_v1`).
- Tests that demonstrate common UI flows: `test/buyer_flow_test.dart`, `test/landing_screen_test.dart`, `test/signup_screen_test.dart`.

What AI agents should NOT guess
- Do not assume a remote backend: persistence is local via SharedPreferences unless code explicitly uses Firebase Database/Firestore.
- Do not change SharedPreferences keys or map formats without also providing a safe migration (tests should reflect migrations).

When making changes, practical suggestions
- When touching auth/email-link flows, add or update tests that assert SharedPreferences keys (`email_for_sign_in`) and the expected navigation.
- When changing Order timelines, update `test/` to adapt to the new delays or introduce flags to make timers deterministic in tests.
- Prefer using `ValueKey` for new interactable widgets to keep UI tests stable.

If you need more context
- Ask for: (1) which platform(s) we should target (Android/iOS/web), (2) whether to add CI, and (3) if Firebase project credentials will be changed.

---
Please review this file for anything I missed or for project-specific nitpicks (naming, extra keys to document). I can iterate quickly on any additions or rewording.  
