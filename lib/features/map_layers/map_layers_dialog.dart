import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/badge_service.dart';
import 'map_layers_provider.dart';

class MapLayersDialog extends ConsumerWidget {
  const MapLayersDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLayers = ref.watch(activeMapLayersProvider);
    final activeNotifier = ref.read(activeMapLayersProvider.notifier);

    // Group available layers by group name
    final groupedLayers = <String, List<dynamic>>{};
    for (final layer in availableLayers) {
      groupedLayers.putIfAbsent(layer.group, () => []).add(layer);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth >= 600 ? 3 : 2;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupedLayers.entries.map((entry) {
                      final groupName = entry.key;
                      final layers = entry.value;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              groupName.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    letterSpacing: 1.1,
                                  ),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.25,
                            ),
                            itemCount: layers.length,
                            itemBuilder: (context, index) {
                              final layer = layers[index];
                              final isEnabled = activeLayers.contains(layer.id);
                              final hasConfigure = layer.onConfigure != null;

                              return InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  if (hasConfigure) {
                                    layer.onConfigure!(context);
                                  } else {
                                    activeNotifier.toggleLayer(layer.id);
                                    if (!isEnabled && layer.id == 'depth_bathymetry') {
                                      final result = await ref
                                          .read(badgeServiceProvider)
                                          .onDepthLayerToggled();
                                      if (!context.mounted) return;
                                      showBadgeUnlocks(context, result);
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isEnabled
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isEnabled
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            layer.icon,
                                            size: 28,
                                            color: isEnabled
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimaryContainer
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .outline,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            layer.displayName,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: isEnabled
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              color: isEnabled
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                            ),
                                          ),
                                          if (hasConfigure) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              layer.currentConfigLabel ?? 'Choose',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    fontSize: 10,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      if (isEnabled)
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Icon(
                                            Icons.check_circle,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: activeLayers.isEmpty
                        ? null
                        : () {
                            activeNotifier.clearAll();
                          },
                    child: const Text('Clear all'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
