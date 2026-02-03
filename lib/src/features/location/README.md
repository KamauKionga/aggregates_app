# Location feature

This feature provides:
- `MapPicker` widget: draggable pin, address search (geocoding fallback), save location
- `LocationModel` - lat, lng, address
- `LocationPermissionService` - wrapper around Geolocator
- `LocationSaveService` - saves location to Firestore under `users/{uid}/lastLocation` and `users/{uid}/locations`

Platform & setup:
- Google Maps API key required
  - Android: set `com.google.android.geo.API_KEY` in `android/app/src/main/AndroidManifest.xml` per `google_maps_flutter` docs
  - iOS: set `GMSApiKey` in `AppDelegate` / Info.plist as needed
  - Web: add API key to `web/index.html` per Google Maps JS API docs
- Phone/Geolocation permissions: add platform descriptions to Android/iOS manifests

Security & rules:
- Buyers MUST NOT see quarry or truck locations. `MapPicker` hides other entity markers when current user role is `UserRole.buyer`.
- Buyers who have an active order (business logic elsewhere) are not shown map UI; instead they will see only **distance remaining** and **ETA**.

Notes & next steps:
- For a production-grade place search use Google Places Autocomplete (server & client APIs) rather than the `geocoding` fallback used here.
- Consider adding unit tests and integration tests with the Firebase emulator and mock geolocation.
