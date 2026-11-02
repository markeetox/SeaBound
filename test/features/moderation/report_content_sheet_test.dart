import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/moderation/report_content_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestSheet({
    required String contentType,
    required String contentId,
    required String contentTitle,
    required String authorId,
    required String authorName,
  }) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 900,
            width: 500,
            child: ReportContentSheet(
              contentType: contentType,
              contentId: contentId,
              contentTitle: contentTitle,
              authorId: authorId,
              authorName: authorName,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('ReportContentSheet renders categories and explanation field', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestSheet(
      contentType: 'spot',
      contentId: 'spot_1',
      contentTitle: 'Biscayne Bay Secret',
      authorId: 'author_uid',
      authorName: 'Captain Jack',
    ));
    await tester.pumpAndSettle();

    expect(find.text('Report Content'), findsOneWidget);
    expect(find.textContaining('Reporting SPOT: "Biscayne Bay Secret" by Captain Jack'), findsOneWidget);
    expect(find.text('Inappropriate or offensive content'), findsOneWidget);
    expect(find.text('Submit Report'), findsOneWidget);

    // Enter explanation text
    await tester.enterText(find.byType(TextField), 'Violates local fishing rules');
    await tester.pump();
    expect(find.text('Violates local fishing rules'), findsOneWidget);
  });

  testWidgets('Selecting category updates UI selection', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestSheet(
      contentType: 'spot',
      contentId: 'spot_1',
      contentTitle: 'Biscayne Bay Secret',
      authorId: 'author_uid',
      authorName: 'Captain Jack',
    ));
    await tester.pumpAndSettle();

    final categoryTile = find.text('Inappropriate or offensive content');
    await tester.tap(categoryTile);
    await tester.pumpAndSettle();

    // Verify radio checked
    expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
  });
}
