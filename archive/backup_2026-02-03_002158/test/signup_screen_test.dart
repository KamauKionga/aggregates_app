import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/screens/signup_screen.dart';
import 'package:aggregates_app/Models/user_roles.dart';

void main() {
  testWidgets('SignupScreen shows email form by default and trucker fields', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SignupScreen(role: UserRole.trucker)));

    expect(find.text('Trucker Signup'), findsOneWidget);

    // Email form fields by key
    expect(find.byKey(const ValueKey('full_name')), findsOneWidget);
    expect(find.byKey(const ValueKey('phone_number')), findsOneWidget);
    expect(find.byKey(const ValueKey('email')), findsOneWidget);

    // Trucker specific fields by key
    expect(find.byKey(const ValueKey('vehicle_number')), findsOneWidget);
    expect(find.byKey(const ValueKey('driving_license')), findsOneWidget);
  });

  testWidgets('SignupScreen toggles to Google signup', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: SignupScreen(role: UserRole.buyer)));

    // Tap the Google toggle
    await tester.tap(find.text('Google'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('google_button')), findsOneWidget);
  });
}
