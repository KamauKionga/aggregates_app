import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/screens/buyer_order_screen.dart';

void main() {
  testWidgets('Buyer places order and proceeds to checkout', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: BuyerOrderScreen()));

    // Wait for settings to load
    await tester.pumpAndSettle();

    // Select aggregate type
    expect(find.byKey(const ValueKey('aggregate_type')), findsOneWidget);

    // Select tonnage dropdown and pick 28 (second option if default 14)
    await tester.tap(find.byKey(const ValueKey('tonnage')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('28').last);
    await tester.pumpAndSettle();

    // Enter a distance
    await tester.enterText(find.byType(TextField).last, '10');
    await tester.pumpAndSettle();

    // Proceed to invoice
    await tester.tap(find.text('Proceed to Invoice & Checkout'));
    await tester.pumpAndSettle();

    // On invoice, proceed to checkout
    expect(find.text('Invoice'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('proceed_to_checkout')));
    await tester.pumpAndSettle();

    // On checkout, open MPESA dialog
    await tester.tap(find.byKey(const ValueKey('pay_mpesa')));
    await tester.pumpAndSettle();

    // Enter phone and simulate send
    await tester.enterText(find.byKey(const ValueKey('mpesa_phone')), '0712345678');
    await tester.tap(find.byKey(const ValueKey('mpesa_send')));
    await tester.pumpAndSettle();

    expect(find.textContaining('simulated'), findsOneWidget);
  });
}
