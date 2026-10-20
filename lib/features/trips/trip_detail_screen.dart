import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/gradient_background.dart';
import '../../core/map_layer_config.dart';
import '../profile/profile_providers.dart';
import 'trip_model.dart';
import 'trips_providers.dart';
import 'trips_screen.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Trip?'),
          content: Text('Are you sure you want to delete "$title"? This action cannot be undone.'),
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
      final repository = ref.read(tripsRepositoryProvider);
      await repository.deleteTrip(tripId);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  void _showShareSheet(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _ShareTripSheet(trip: trip),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripDetailAsync = ref.watch(tripDetailStreamProvider(tripId));

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Trip Details'),
        actions: [
          tripDetailAsync.when(
            data: (trip) {
              if (trip == null) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'share') {
                    _showShareSheet(context, trip);
                  } else if (value == 'edit') {
                    context.push('/trips/$tripId/edit');
                  } else if (value == 'delete') {
                    _confirmDelete(context, ref, trip.title);
                  }
                },
                itemBuilder: (BuildContext context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_outlined),
                        SizedBox(width: 8),
                        Text('Share with Friends'),
                      ],
                    ),
                  ),
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
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: tripDetailAsync.when(
        data: (trip) {
          if (trip == null) {
            return const Center(child: Text('Trip not found.'));
          }

          final formattedDate = DateFormat.yMMMMd().format(trip.date);
          final userDoc = ref.watch(userDocStreamProvider).asData?.value;
          final userBgHex = userDoc?['avatarBgColor'] as String?;
          final userBgVal = userBgHex != null && userBgHex.startsWith('#')
              ? int.tryParse(userBgHex.replaceFirst('#', '0xFF'))
              : null;
          final pointerColor = userBgVal != null ? Color(userBgVal) : const Color(0xFFD1142A);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        TripReactionButtons(trip: trip),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            trip.locationName,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: trip.locationCoordinates,
                            initialZoom: 12.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: MapLayerConfig.openStreetMapTileUrl,
                              userAgentPackageName: 'com.onerevamp.seabound',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: trip.locationCoordinates,
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.location_on,
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
                    const Divider(height: 32),
                    if (trip.species.isNotEmpty) ...[
                      Text(
                        'Species Targeted / Caught',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: trip.species.map((species) {
                          return Chip(label: Text(species));
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (trip.notes.isNotEmpty) ...[
                      Text(
                        'Notes',
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
                          trip.notes,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showShareSheet(context, trip),
                            icon: const Icon(Icons.share),
                            label: const Text('Share Trip'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/trips/$tripId/edit');
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading trip: $e')),
      ),
    ),
    );
  }
}

class _ShareTripSheet extends ConsumerStatefulWidget {
  final Trip trip;

  const _ShareTripSheet({required this.trip});

  @override
  ConsumerState<_ShareTripSheet> createState() => _ShareTripSheetState();
}

class _ShareTripSheetState extends ConsumerState<_ShareTripSheet> {
  late Set<String> _selectedFriendUids;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedFriendUids = Set.from(widget.trip.sharedWith);
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(userFriendsStreamProvider);

    return SafeArea(
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
                  'Share Trip with Friends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Select friends who can view this trip details:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            friendsAsync.when(
              data: (friends) {
                if (friends.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: OceanThemeExtension.defaultTokens.cyan.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You have not added any friends yet.\nVisit a user profile to add friends!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: friends.length,
                    itemBuilder: (context, index) {
                      final friend = friends[index];
                      final isChecked = _selectedFriendUids.contains(friend.uid);

                      return CheckboxListTile(
                        value: isChecked,
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              _selectedFriendUids.add(friend.uid);
                            } else {
                              _selectedFriendUids.remove(friend.uid);
                            }
                          });
                        },
                        secondary: SizedBox(
                          width: 48,
                          height: 48,
                          child: friend.avatarId != null && friend.avatarId!.isNotEmpty
                              ? Image.asset(
                                  'assets/avatars/${friend.avatarId}.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(Icons.person, color: Colors.white, size: 28),
                                )
                              : const Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                        title: Text(
                          friend.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error loading friends: $e'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving
                    ? null
                    : () async {
                        setState(() {
                          _isSaving = true;
                        });
                        final repo = ref.read(tripsRepositoryProvider);
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        await repo.updateTripSharing(widget.trip.id, _selectedFriendUids.toList());
                        if (mounted) {
                          navigator.pop();
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('Trip sharing settings updated!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: const Text('Save Sharing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
