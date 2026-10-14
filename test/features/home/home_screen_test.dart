import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/map_layer_config.dart';
import 'package:seabound/features/alerts/alerts_providers.dart';
import 'package:seabound/features/home/home_screen.dart';
import 'package:seabound/features/map_layers/map_layers_provider.dart';
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

    // Verify 6 radial buttons exist (Fish locations, Waves, Depth on left; Trips, Alerts, Spots on right)
    expect(find.text('Fish locations'), findsOneWidget);
    expect(find.text('Waves'), findsOneWidget);
    expect(find.text('Depth'), findsOneWidget);
    expect(find.text('Trips'), findsOneWidget);
    expect(find.text('Alerts'), findsOneWidget);
    expect(find.text('Spots'), findsOneWidget);

    // Verify bottom-left red SOS button exists
    expect(find.text('SOS'), findsOneWidget);
  });

  testWidgets('HomeScreen radial buttons for Waves and Depth activate map layers', (WidgetTester tester) async {
    Set<String>? activeLayers;

    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          activeLayers = ref.watch(activeMapLayersProvider);
          return const HomeScreen();
        },
      ),
      overrides: [
        userDocStreamProvider.overrideWith((ref) => Stream.value({
              'username': 'CaptainJack',
            })),
        userEarnedBadgesProvider.overrideWith((ref) => Stream.value({})),
        alertsNotifierProvider.overrideWith(() => AlertsNotifier()),
      ],
    );

    // Tap Waves radial button
    await tester.tap(find.text('Waves'));
    await tester.pumpAndSettle();

    expect(activeLayers, contains(MapLayerConfig.wavesId));

    // Tap Depth radial button
    await tester.tap(find.text('Depth'));
    await tester.pumpAndSettle();

    expect(activeLayers, contains(MapLayerConfig.depthBathymetryId));
  });

  testWidgets('HomeScreen Fish locations shows coming soon SnackBar on tap', (WidgetTester tester) async {
    await pumpApp(
      tester,
      const HomeScreen(),
      overrides: [
        userDocStreamProvider.overrideWith((ref) => Stream.value({
              'username': 'CaptainJack',
            })),
        userEarnedBadgesProvider.overrideWith((ref) => Stream.value({})),
        alertsNotifierProvider.overrideWith(() => AlertsNotifier()),
      ],
    );

    await tester.tap(find.text('Fish locations'));
    await tester.pumpAndSettle();

    expect(find.text('Fish locations feature coming soon.'), findsOneWidget);
  });
}
