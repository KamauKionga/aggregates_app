import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

/// Bootstrap initializes required services and runs the app.
/// NOTE: Replace with `DefaultFirebaseOptions` for web if you generated
/// firebase_options via `flutterfire configure`.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ProviderScope(child: App()));
}
