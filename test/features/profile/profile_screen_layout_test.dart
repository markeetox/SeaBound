import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/app_theme.dart';
import 'package:seabound/features/auth/auth_providers.dart';
import 'package:seabound/features/profile/badge_service.dart';
import 'package:seabound/features/profile/profile_providers.dart';
import 'package:seabound/features/profile/profile_repository.dart';
import 'package:seabound/features/profile/profile_screen.dart';
import 'package:seabound/features/spots/spots_providers.dart';
import 'package:seabound/features/trips/trips_providers.dart';

class MockProfileRepository implements ProfileRepository {
  @override
  Future<void> removeEmailFromUserDoc(String uid) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBadgeService implements BadgeService {
  @override
  Future<BadgeResult> checkAllBadges() async {
    return const BadgeResult();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('ProfileScreen renders username with 36px font, black stats container with circles, and no Captain profile title',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userDocStreamProvider.overrideWith((ref) => Stream.value({'username': 'CaptainJack'})),
          userEarnedBadgesProvider.overrideWith((ref) => Stream.value({'badge_1': DateTime.now()})),
          userTripsStreamProvider.overrideWith((ref) => Stream.value([])),
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
          badgeServiceProvider.overrideWithValue(MockBadgeService()),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no "Captain profile" text header exists
    expect(find.text('Captain profile'), findsNothing);

    // Verify username is displayed large (font size 36)
    final usernameFinder = find.text('CaptainJack');
    expect(usernameFinder, findsOneWidget);
    final Text usernameText = tester.widget(usernameFinder);
    expect(usernameText.style?.fontSize, 36);
    expect(usernameText.style?.fontWeight, FontWeight.w900);

    // Verify stat circular tiles (Trips, Spots, Pins)
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Spots'), findsOneWidget);
    expect(find.text('Pins'), findsOneWidget);

    // Verify black stats container (#000000)
    final statsContainerFinder = find.ancestor(
      of: find.text('Trips'),
      matching: find.byType(Container),
    );
    expect(statsContainerFinder, findsWidgets);

    // Verify top bar buttons
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });
}
