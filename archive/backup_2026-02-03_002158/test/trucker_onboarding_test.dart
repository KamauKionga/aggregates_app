import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/screens/individual_onboarding_screen.dart';
import 'package:aggregates_app/screens/organization_onboarding_screen.dart';
import 'package:aggregates_app/services/trucker_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Individual onboarding saves and uploads a document', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: IndividualOnboardingScreen(userId: 'user1', email: 'truck1@example.com', phone: '0711111111')));

    // Fill the form
    await tester.enterText(find.byType(TextFormField).at(0), 'John Doe');
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.enterText(find.byType(TextFormField).at(2), '1980-01-01');
    await tester.enterText(find.byType(TextFormField).at(3), 'A1234567');
    await tester.enterText(find.byType(TextFormField).at(4), '10');

    // Submit
    await tester.tap(find.text('Save & Continue'));
    await tester.pumpAndSettle();

    // Should be on Document Upload screen
    expect(find.text('Upload Documents'), findsOneWidget);

    // Should show required documents
    expect(find.textContaining('National ID (Front)'), findsOneWidget);

    // Tap upload for first document
    final uploadButton = find.widgetWithText(ElevatedButton, 'Upload').first;
    await tester.tap(uploadButton);

    // Pump repeatedly until mock upload completes and UI updates
    bool uploaded = false;
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 300));
      if (find.textContaining('Uploaded: mock://').evaluate().isNotEmpty) {
        uploaded = true;
        break;
      }
    }

    expect(uploaded, true, reason: 'Mock upload should complete and show a mock URL');

    // Verify the trucker was saved in repository
    final t = await TruckerRepository.getByUserId('user1');
    expect(t, isNotNull);
    expect(t!.documents.any((d) => d.url != null), isTrue);
  });

  testWidgets('Organization onboarding saves company and creates documents', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: OrganizationOnboardingScreen(userId: 'org1', email: 'org@example.com', phone: '070000000')));

    // Fill required fields
    await tester.enterText(find.byType(TextFormField).at(0), 'Acme Ltd');
    await tester.enterText(find.byType(TextFormField).at(1), 'BR-1234');
    await tester.enterText(find.byType(TextFormField).at(2), '2000-01-01');
    await tester.enterText(find.byType(TextFormField).at(3), 'KRA-9876');
    await tester.enterText(find.byType(TextFormField).at(4), '10 Downing St');
    await tester.enterText(find.byType(TextFormField).at(5), 'contact@acme.com');
    await tester.enterText(find.byType(TextFormField).at(6), 'Rep Person');
    await tester.enterText(find.byType(TextFormField).at(7), '87654321');

    // Submit: ensure button is present and tap it
    await tester.pumpAndSettle();
    final saveButton = find.widgetWithText(ElevatedButton, 'Save & Continue');
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();
    await tester.tap(saveButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // Should navigate to Fleet Management placeholder
    expect(find.text('Fleet Management'), findsOneWidget);

    // Verify the trucker record exists
    final t = await TruckerRepository.getByUserId('org1');
    expect(t, isNotNull);
    expect(t!.type.toString().contains('organization'), isTrue);
    expect(t.documents.length, greaterThanOrEqualTo(1));
  });
}
