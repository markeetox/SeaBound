import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/core/app_theme.dart';

Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<dynamic> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides.cast(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        darkTheme: AppTheme.darkTheme,
        home: widget,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
