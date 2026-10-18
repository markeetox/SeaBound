import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:seabound/features/auth/auth_providers.dart';
import 'package:seabound/features/map/location_providers.dart';
import 'package:seabound/features/map/location_service.dart';
import 'package:seabound/features/profile/profile_providers.dart';
import 'package:seabound/features/spots/spot_form_screen.dart';

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
  testWidgets('SpotFormScreen "Use my current location" updates pinned location text',
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
      const SpotFormScreen(),
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(FakeUser())),
        userDocStreamProvider.overrideWith((ref) => Stream.value({})),
        userProfileProvider.overrideWith((ref) => Stream.value({})),
        locationServiceProvider.overrideWithValue(FakeLocationService(mockPos)),
      ],
    );

    expect(find.text('Add New Spot'), findsOneWidget);

    final useLocationButton = find.text('Use my location');
    expect(useLocationButton, findsOneWidget);

    await tester.tap(useLocationButton);
    await tester.pumpAndSettle();

    expect(find.text('Pinned: 25.7617, -80.1918'), findsOneWidget);
  });
}
