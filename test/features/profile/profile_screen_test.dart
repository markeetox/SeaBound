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
  testWidgets('Tapping profile avatar 5 times triggers secret easter egg animation',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          userDocStreamProvider.overrideWith((ref) => Stream.value({'username': 'CaptainJack', 'avatarId': 'avatar_01'})),
          userEarnedBadgesProvider.overrideWith((ref) => Stream.value({})),
          userTripsStreamProvider.overrideWith((ref) => Stream.value([])),
          allSpotsStreamProvider.overrideWith((ref) => Stream.value([])),
          userFriendsStreamProvider.overrideWith((ref) => Stream.value([])),
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

    final easterEggFinder = find.byKey(const ValueKey('secret_easter_egg_image'));
    final avatarFinder = find.byKey(const ValueKey('profile_avatar_tap_area'));

    // Before tapping 5 times, easter egg image is not visible
    expect(easterEggFinder, findsNothing);
    expect(avatarFinder, findsOneWidget);

    // Tap 4 times
    for (int i = 0; i < 4; i++) {
      await tester.tap(avatarFinder);
      await tester.pump();
    }
    expect(easterEggFinder, findsNothing);

    // 5th tap triggers the animation
    await tester.tap(avatarFinder);
    await tester.pump(const Duration(milliseconds: 100));

    // Easter egg image is now rendered
    expect(easterEggFinder, findsOneWidget);

    // Pump past the animation duration (2500 ms)
    await tester.pump(const Duration(milliseconds: 2600));

    // After animation finishes, it returns SizedBox.shrink() so image is gone
    expect(easterEggFinder, findsNothing);
  });
}
