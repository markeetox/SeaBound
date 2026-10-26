import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/badge_service.dart';
import 'map_layers_provider.dart';

class MapLayersSheet extends ConsumerWidget {
  const MapLayersSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLayers = ref.watch(activeMapLayersProvider);
    final activeNotifier = ref.read(activeMapLayersProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Map Layers',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            ...availableLayers.map((layer) {
              final isEnabled = activeLayers.contains(layer.id);
              return SwitchListTile(
                secondary: Icon(
                  layer.icon,
                  color: isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                ),
                title: Text(
                  layer.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                value: isEnabled,
                onChanged: (_) async {
                  activeNotifier.toggleLayer(layer.id);
                  if (!isEnabled && layer.id == 'depth_bathymetry') {
                    final result = await ref
                        .read(badgeServiceProvider)
                        .onDepthLayerToggled();
                    if (!context.mounted) return;
                    showBadgeUnlocks(context, result);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
