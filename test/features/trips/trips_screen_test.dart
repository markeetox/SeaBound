import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/trips/trip_model.dart';
import 'package:seabound/features/trips/trips_providers.dart';
import 'package:seabound/features/trips/trips_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('TripsScreen renders empty state when no trips exist',
      (WidgetTester tester) async {
    await pumpApp(
      tester,
      const TripsScreen(),
      overrides: [
        userTripsStreamProvider.overrideWith((ref) => Stream.value([])),
      ],
    );

    expect(find.text('Fishing Trips'), findsOneWidget);
    expect(find.text('My Trips'), findsOneWidget);
    expect(find.text('Shared with Me'), findsOneWidget);
    expect(find.text('No Trips Logged Yet'), findsOneWidget);
    expect(
      find.text('Start logging your fishing adventures, catches, and secret spots!'),
      findsOneWidget,
    );
    expect(find.text('Log First Trip'), findsOneWidget);
  });

  testWidgets('TripsScreen renders list of trips when data is available',
      (WidgetTester tester) async {
    final sampleTrip = Trip(
      id: 'trip1',
      userId: 'user1',
      title: 'Ocean Voyage',
      date: DateTime(2025, 4, 15),
      locationName: 'Key West',
      species: const ['Mahi Mahi', 'Sailfish'],
      notes: 'Bait used: squid.',
    );

    await pumpApp(
      tester,
      const TripsScreen(),
      overrides: [
        userTripsStreamProvider.overrideWith((ref) => Stream.value([sampleTrip])),
      ],
    );

    expect(find.text('Ocean Voyage'), findsOneWidget);
    expect(find.text('Key West'), findsOneWidget);
    expect(find.text('Mahi Mahi'), findsOneWidget);
    expect(find.text('Sailfish'), findsOneWidget);
  });
}
