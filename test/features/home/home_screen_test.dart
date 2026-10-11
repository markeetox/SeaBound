import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/home/home_screen.dart';
import 'package:seabound/features/profile/profile_providers.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('HomeScreen renders central avatar/username/level circle and 6 radial shortcut buttons',
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
      ],
    );

    // Verify username and level are rendered inside the central circle
    expect(find.text('CaptainJack'), findsOneWidget);
    expect(find.textContaining('Lvl 1'), findsOneWidget);

    // Verify 6 blank radial shortcut buttons exist
    expect(find.byTooltip('Shortcut 1'), findsOneWidget);
    expect(find.byTooltip('Shortcut 2'), findsOneWidget);
    expect(find.byTooltip('Shortcut 3'), findsOneWidget);
    expect(find.byTooltip('Shortcut 4'), findsOneWidget);
    expect(find.byTooltip('Shortcut 5'), findsOneWidget);
    expect(find.byTooltip('Shortcut 6'), findsOneWidget);

    // Verify bottom-left red SOS button exists
    expect(find.text('SOS'), findsOneWidget);
  });
}
