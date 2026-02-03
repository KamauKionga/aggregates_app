import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aggregates_app/screens/organization_onboarding_screen.dart';
import 'package:aggregates_app/services/trucker_repository.dart';
import 'package:aggregates_app/Models/trucker_model.dart';
import 'package:aggregates_app/Models/truck_model.dart';
import 'package:aggregates_app/Models/enums.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Add, edit, remove truck flow', (WidgetTester tester) async {
    // Create a trucker record first
    final t = TruckerModel(id: 't1', userId: 'org1', email: 'org@example.com', phone: '070000000', type: TruckerType.organization);
    await TruckerRepository.saveTrucker(t);

    await tester.pumpWidget(MaterialApp(home: OrganizationFleetScreen(truckerId: 't1')));
    await tester.pumpAndSettle();

    // Add truck
    final addTruck = find.byKey(const ValueKey('add_truck'));
    expect(addTruck, findsOneWidget);
    await tester.tap(addTruck);
    await tester.pumpAndSettle();

    // Fill add truck form
    await tester.enterText(find.byType(TextFormField).at(0), 'KAA 123A');
    await tester.enterText(find.byType(TextFormField).at(1), 'Tipper');
    await tester.enterText(find.byType(TextFormField).at(2), '14');
    await tester.enterText(find.byType(TextFormField).at(3), '4');
    await tester.enterText(find.byType(TextFormField).at(4), 'Diesel');
    await tester.enterText(find.byType(TextFormField).at(5), '2015');

    final saveTruck = find.byKey(const ValueKey('save_truck'));
    expect(saveTruck, findsOneWidget);
    await tester.tap(saveTruck);
    await tester.pumpAndSettle();

    // Truck should be visible
    expect(find.text('KAA 123A'), findsOneWidget);

    // Get truck id from repository
    final saved = await TruckerRepository.getById('t1');
    expect(saved!.trucks.length, 1);
    final truckId = saved.trucks.first.id;

    // Edit truck
    final editButton = find.byKey(ValueKey('edit_truck_$truckId'));
    expect(editButton, findsOneWidget);
    await tester.tap(editButton);
    await tester.pumpAndSettle();

    // Change registration
    await tester.enterText(find.byType(TextFormField).at(0), 'KBB 999B');
    final updateButton = find.byKey(const ValueKey('update_truck'));
    expect(updateButton, findsOneWidget);
    await tester.tap(updateButton);
    await tester.pumpAndSettle();

    expect(find.text('KBB 999B'), findsOneWidget);

    // Remove truck
    final deleteButton = find.byKey(ValueKey('delete_truck_$truckId'));
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Confirm remove dialog
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();

    expect(find.text('KBB 999B'), findsNothing);
  });

  testWidgets('Add driver and assign to truck', (WidgetTester tester) async {
    final truck = TruckModel(id: const Uuid().v4(), registrationNumber: 'KCC 001', truckType: 'Tipper', payloadTons: 14.0, axles: 4, fuelType: 'Diesel', year: 2016);
    final t = TruckerModel(id: 't2', userId: 'org2', email: 'org2@example.com', phone: '070000001', type: TruckerType.organization, trucks: [truck]);
    await TruckerRepository.saveTrucker(t);

    await tester.pumpWidget(MaterialApp(home: OrganizationFleetScreen(truckerId: 't2')));
    await tester.pumpAndSettle();

    final addDriver = find.byKey(const ValueKey('add_driver'));
    expect(addDriver, findsOneWidget);
    await tester.tap(addDriver);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Driver One');
    await tester.enterText(find.byType(TextFormField).at(1), '12345678');
    await tester.enterText(find.byType(TextFormField).at(2), '0712345678');
    await tester.enterText(find.byType(TextFormField).at(3), 'DL-12345');

    final saveDriver = find.byKey(const ValueKey('save_driver'));
    expect(saveDriver, findsOneWidget);
    await tester.tap(saveDriver);
    await tester.pumpAndSettle();

    // Verify driver appears
    expect(find.text('Driver One'), findsOneWidget);

    final saved = await TruckerRepository.getById('t2');
    expect(saved!.drivers.length, 1);
    expect(saved.drivers.first.assignedTruckId, isNotNull);
  });
}