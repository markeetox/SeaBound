import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/alerts/alerts_providers.dart';
import 'package:seabound/features/home/home_screen.dart';
import 'package:seabound/features/profile/profile_providers.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('HomeScreen renders background, top weather & alert banner, central circle and radial buttons',
      (WidgetTester tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [
        userDocStreamProvider.overrideWith((ref) => Stream.value({
              'username': 'CaptainJack',
              'avatarId': 'avatar_01',
            })),
        userEarnedBadgesProvider.overrideWith((ref) => Stream.value({})),
        alertsNotifierProvider.overrideWith(() => AlertsNotifier()),
      ],
    );

    // Verify username and level are rendered inside the central circle
    expect(find.text('CaptainJack'), findsOneWidget);
    expect(find.textContaining('Lvl 1'), findsOneWidget);

    // Verify top weather info and alert banner
    expect(find.textContaining('78°F Sunny'), findsOneWidget);
    expect(find.textContaining('Wind: 14 mph E'), findsOneWidget);
    expect(find.textContaining('No Active Local Marine Alerts'), findsOneWidget);

    // Verify 6 side edge tabs exist (Trips, Spots, Alerts on left; Profile, Weather, Settings on right)
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Spots'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Weather'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify bottom-left red SOS button exists
    expect(find.text('SOS'), findsOneWidget);
  });
}
