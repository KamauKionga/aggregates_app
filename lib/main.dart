// Entrypoint: calls app bootstrap which initializes Firebase and
// runs the app inside a ProviderScope.
import 'src/app/bootstrap.dart';

/// Starting point for the application.
/// Delegates initialization to `bootstrap()`.
Future<void> main() async {
  await bootstrap();
}
