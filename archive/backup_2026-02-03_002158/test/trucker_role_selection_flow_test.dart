import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/screens/landing_screens.dart';
import 'package:aggregates_app/screens/trucker_type_selection_screen.dart';
import 'package:aggregates_app/screens/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Selecting Trucker -> Individual navigates to Trucker signup with fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    // Tap Trucker role
    final truckerBtn = find.byKey(const ValueKey('role_Trucker'));
    expect(truckerBtn, findsOneWidget);
    await tester.tap(truckerBtn);
    await tester.pumpAndSettle();

    // We should see the Trucker type selection screen
    expect(find.text('Trucker Type'), findsOneWidget);

    // Tap Individual Trucker
    final individualBtn = find.byKey(const ValueKey('individual_trucker'));
    expect(individualBtn, findsOneWidget);
    await tester.tap(individualBtn);
    await tester.pumpAndSettle();

    // Should navigate to Signup screen configured for trucker
    expect(find.text('Trucker Signup'), findsOneWidget);

    // County field and terms checkboxes should be present for trucker signup
    expect(find.byKey(const ValueKey('county')), findsOneWidget);
    expect(find.byKey(const ValueKey('accept_terms')), findsOneWidget);
    expect(find.byKey(const ValueKey('accept_data_policy')), findsOneWidget);
  });
}
