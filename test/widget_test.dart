import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/auth/auth_providers.dart';
import 'package:seabound/main.dart';

void main() {
  testWidgets('App launches and displays Login screen initial state when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const SeaboundApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Seabound'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text("Don't have an account? Sign Up"), findsOneWidget);
  });

  testWidgets('Navigates from Login to Sign Up screen when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
        ],
        child: const SeaboundApp(),
      ),
    );
    await tester.pumpAndSettle();

    final signupButton = find.text("Don't have an account? Sign Up");
    expect(signupButton, findsOneWidget);
    await tester.tap(signupButton);
    await tester.pumpAndSettle();

    expect(find.text('Join Seabound Community'), findsOneWidget);
  });
}
