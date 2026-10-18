import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seabound/features/auth/auth_providers.dart';
import 'package:seabound/features/map/location_providers.dart';
import 'package:seabound/features/map/location_service.dart';
import 'package:seabound/features/trips/trip_form_screen.dart';

import '../../helpers/pump_app.dart';

class FakeUser extends Fake implements User {
  @override
  String get uid => 'test_user_id';

  @override
  String? get displayName => 'Test Captain';
}

class FakeLocationService implements LocationService {
  final Position position;
  FakeLocationService(this.position);

  @override
  Future<Position> getCurrentPosition() async => position;

  @override
  Future<LocationPermission> checkPermission() async => LocationPermission.whileInUse;

  @override
  Future<LocationPermission> requestPermission() async => LocationPermission.whileInUse;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Stream<Position> getPositionStream() => Stream.value(position);
}

void main() {
  testWidgets('TripFormScreen "Use my location" button populates location field',
      (WidgetTester tester) async {
    final mockPos = Position(
      latitude: 25.7617,
      longitude: -80.1918,
      timestamp: DateTime.now(),
      accuracy: 1.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    await pumpApp(
      tester,
      const TripFormScreen(),
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(FakeUser())),
        locationServiceProvider.overrideWithValue(FakeLocationService(mockPos)),
      ],
    );

    expect(find.text('Log New Trip'), findsOneWidget);

    final useLocationButton = find.byTooltip('Use my location');
    expect(useLocationButton, findsOneWidget);

    await tester.tap(useLocationButton);
    await tester.pumpAndSettle();

    expect(find.text('25.7617, -80.1918'), findsOneWidget);
  });
}
