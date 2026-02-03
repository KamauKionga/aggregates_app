import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/landing_screens.dart';
import 'firebase_options.dart';

// NOTE: Dynamic link handling (automatic email-link sign-in) requires
// the `firebase_dynamic_links` package and Android/iOS setup in Firebase.
// I added the send-sign-in-link logic in `AuthService.sendSignInLinkToEmail`.
// To enable automatic handling when the user taps the email link, add
// `firebase_dynamic_links` to `pubspec.yaml`, run `flutter pub get`,
// and then wire `FirebaseDynamicLinks.instance.onLink`/`getInitialLink`
// to call `AuthService.signInWithEmailLink` (example code was previously added).

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Aggregates App',
      debugShowCheckedModeBanner: false,
      home: const LandingScreen(),
    );
  }
}
