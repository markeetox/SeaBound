import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_providers.dart';
import 'spots_providers.dart';

class SpotDetailScreen extends ConsumerWidget {
  final String spotId;

  const SpotDetailScreen({super.key, required this.spotId});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String spotName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Spot?'),
          content: Text(
              'Are you sure you want to delete "$spotName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final repository = ref.read(spotsRepositoryProvider);
      await repository.deleteSpot(spotId);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userDoc = ref.watch(userDocStreamProvider).asData?.value;
    final userBgHex = userDoc?['avatarBgColor'] as String?;
    final userBgVal = userBgHex != null && userBgHex.startsWith('#')
        ? int.tryParse(userBgHex.replaceFirst('#', '0xFF'))
        : null;
    final pointerColor = userBgVal != null ? Color(userBgVal) : Theme.of(context).colorScheme.primary;
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.asData?.value;
    final spotDetailAsync = ref.watch(spotDetailStreamProvider(spotId));

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Spot Details'),
        actions: [
          spotDetailAsync.when(
            data: (spot) {
              if (spot == null || currentUser == null || spot.userId != currentUser.uid) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    context.push('/spots/$spotId/edit');
                  } else if (value == 'delete') {
                    _confirmDelete(context, ref, spot.name);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (error, stackTrace) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: spotDetailAsync.when(
        data: (spot) {
          if (spot == null) {
            return const Center(child: Text('Spot not found.'));
          }

          final isAuthor = currentUser != null && currentUser.uid == spot.userId;
          final formattedDate = spot.createdAt != null
              ? DateFormat.yMMMMd().format(spot.createdAt!)
              : 'Recent';

          final spotLatLng = LatLng(spot.latitude, spot.longitude);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spot.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: spot.userId.isNotEmpty
                              ? () => context.push('/profile/user/${spot.userId}')
                              : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Text(
                            'Shared by ${spot.authorName}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: spotLatLng,
                            initialZoom: 12.0,
                            minZoom: 3.0,
                            maxZoom: 20.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.onerevamp.seabound',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: spotLatLng,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.place,
                                    size: 40,
                                    color: pointerColor,
                                  ),
                                ),
                              ],
                            ),
                            RichAttributionWidget(
                              attributions: [
                                TextSourceAttribution(
                                  'OpenStreetMap contributors',
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (spot.description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          spot.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (spot.species.isNotEmpty) ...[
                      Text(
                        'Species Found Here',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: spot.species.map((species) {
                          return Chip(label: Text(species));
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (isAuthor) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.push('/spots/$spotId/edit');
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Spot'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              onPressed: () =>
                                  _confirmDelete(context, ref, spot.name),
                              icon: const Icon(Icons.delete),
                              label: const Text('Delete Spot'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading spot: $e')),
      ),
    ),
    );
  }
}
