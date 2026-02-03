import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/screens/landing_screens.dart';

void main() {
  testWidgets('LandingScreen navigates to Buyer signup', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    expect(find.text('Who are you?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('role_Buyer')));
    await tester.pumpAndSettle();

    expect(find.text('Buyer Signup'), findsOneWidget);
  });

  testWidgets('LandingScreen navigates to Agent signup', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    await tester.tap(find.byKey(const ValueKey('role_Agent')));
    await tester.pumpAndSettle();

    expect(find.text('Agent Signup'), findsOneWidget);
  });

  testWidgets('LandingScreen navigates to Trucker signup', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    await tester.tap(find.byKey(const ValueKey('role_Trucker')));
    await tester.pumpAndSettle();

    expect(find.text('Trucker Signup'), findsOneWidget);
  });
}
