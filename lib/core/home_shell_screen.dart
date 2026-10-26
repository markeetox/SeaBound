import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/alerts_providers.dart';
import 'app_bottom_nav.dart';
import 'gradient_background.dart';

class HomeShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsNotifierProvider);
    final hasAlerts = alertsState.alerts.isNotEmpty;

    // Index 2 is Home tab, Index 4 is Profile tab
    final isHomePage = navigationShell.currentIndex == 2;
    final isProfileTab = navigationShell.currentIndex == 4;

    return GradientBackground(
      variant: isProfileTab ? GradientVariant.red : GradientVariant.blue,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: navigationShell,
        bottomNavigationBar: isHomePage
            ? null
            : AppBottomNav(
                currentIndex: navigationShell.currentIndex,
                onSelect: _onTap,
                hasAlerts: hasAlerts,
              ),
      ),
    );
  }
}
