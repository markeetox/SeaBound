import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/alerts_providers.dart';
import '../features/map_layers/lupita_service.dart';
import '../features/map_layers/map_layers_provider.dart';
import 'app_bottom_nav.dart';
import 'gradient_background.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _lastIndex = 2;

  @override
  void initState() {
    super.initState();
    _lastIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(covariant HomeShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIndex = widget.navigationShell.currentIndex;
    // If previously on Spots (index 1) and now on a different tab, reset map filters
    if (_lastIndex == 1 && currentIndex != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(activeMapLayersProvider.notifier).resetToDefault();
        ref.read(selectedLupitaSpeciesIdProvider.notifier).selectSpecies(null);
      });
    }
    _lastIndex = currentIndex;
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final alertsState = ref.watch(alertsNotifierProvider);
    final hasAlerts = alertsState.alerts.isNotEmpty;

    final currentIndex = widget.navigationShell.currentIndex;
    // Index 2 is Home tab, Index 4 is Profile tab
    final isHomePage = currentIndex == 2;
    final isProfileTab = currentIndex == 4;

    return GradientBackground(
      variant: isProfileTab ? GradientVariant.red : GradientVariant.blue,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: widget.navigationShell,
        bottomNavigationBar: isHomePage
            ? null
            : AppBottomNav(
                currentIndex: currentIndex,
                onSelect: _onTap,
                hasAlerts: hasAlerts,
              ),
      ),
    );
  }
}
