import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../../core/map_layer_config.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_providers.dart';
import 'trip_model.dart';
import 'trips_providers.dart';

enum _TripTab { myTrips, sharedWithMe }

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  _TripTab _selectedTab = _TripTab.myTrips;

  @override
  Widget build(BuildContext context) {
    final tripsAsync = _selectedTab == _TripTab.myTrips
        ? ref.watch(userTripsStreamProvider)
        : ref.watch(sharedTripsStreamProvider);

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 88, bottom: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fishing Trips',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: SegmentedButton<_TripTab>(
                            segments: const [
                              ButtonSegment(
                                value: _TripTab.myTrips,
                                label: Text('My Trips'),
                                icon: Icon(Icons.directions_boat),
                              ),
                              ButtonSegment(
                                value: _TripTab.sharedWithMe,
                                label: Text('Shared with Me'),
                                icon: Icon(Icons.people),
                              ),
                            ],
                            selected: {_selectedTab},
                            onSelectionChanged: (Set<_TripTab> newSelection) {
                              setState(() {
                                _selectedTab = newSelection.first;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        tripsAsync.when(
                          data: (trips) {
                            if (trips.isEmpty) {
                              return _buildEmptyState(context);
                            }
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: trips.length,
                              itemBuilder: (context, index) {
                                final trip = trips[index];
                                return _TripCard(trip: trip);
                              },
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stackTrace) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                'Error loading trips: $error',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Floating Top Bar Overlay with Log Trip action
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FloatingTopBar(
                actions: [
                  FloatingTopBarButton(
                    icon: Icons.add,
                    tooltip: 'Log Trip',
                    onPressed: () {
                      context.push('/trips/add');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_boat_outlined,
              size: 80,
              color: OceanThemeExtension.defaultTokens.cyan.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Trips Logged Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Start logging your fishing adventures, catches, and secret spots!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/trips/add');
              },
              icon: const Icon(Icons.add),
              label: const Text('Log First Trip'),
            ),
          ],
        ),
      ),
    );
  }
}

class TripReactionButtons extends ConsumerWidget {
  final Trip trip;

  const TripReactionButtons({super.key, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authUser = ref.watch(authStateProvider).asData?.value;
    final currentUid = authUser?.uid ?? '';

    final isLiked = trip.isLikedBy(currentUid);
    final isDisliked = trip.isDislikedBy(currentUid);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Thumbs Up
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: currentUid.isEmpty
              ? null
              : () {
                  ref
                      .read(tripsRepositoryProvider)
                      .toggleTripReaction(trip.id, currentUid, true);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLiked ? Icons.thumb_up_alt : Icons.thumb_up_off_alt,
                  size: 20,
                  color: isLiked
                      ? OceanThemeExtension.defaultTokens.cyan
                      : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trip.likeCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isLiked
                        ? OceanThemeExtension.defaultTokens.cyan
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Thumbs Down
        InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: currentUid.isEmpty
              ? null
              : () {
                  ref
                      .read(tripsRepositoryProvider)
                      .toggleTripReaction(trip.id, currentUid, false);
                },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDisliked ? Icons.thumb_down_alt : Icons.thumb_down_off_alt,
                  size: 20,
                  color: isDisliked
                      ? const Color(0xFFFF6B6B)
                      : Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  '${trip.dislikeCount}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDisliked
                        ? const Color(0xFFFF6B6B)
                        : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TripCard extends ConsumerWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedDate = DateFormat.yMMMMd().format(trip.date);
    final userDoc = ref.watch(userDocStreamProvider).asData?.value;
    final userBgHex = userDoc?['avatarBgColor'] as String?;
    final userBgVal = userBgHex != null && userBgHex.startsWith('#')
        ? int.tryParse(userBgHex.replaceFirst('#', '0xFF'))
        : null;
    final pointerColor = userBgVal != null ? Color(userBgVal) : const Color(0xFFD1142A);

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/trips/${trip.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Object Thumbnail: Location Map Preview Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: IgnorePointer(
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: trip.locationCoordinates,
                        initialZoom: 11.0,
                        minZoom: 3.0,
                        maxZoom: 20.0,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
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
                              width: 24,
                              height: 24,
                              child: Icon(
                                Icons.location_on,
                                size: 24,
                                color: pointerColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Content Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            trip.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.white70,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: trip.trailPoints.isNotEmpty
                            ? Colors.amber.shade900.withValues(alpha: 0.6)
                            : OceanThemeExtension.defaultTokens.cyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: trip.trailPoints.isNotEmpty
                              ? Colors.amber.shade600
                              : OceanThemeExtension.defaultTokens.cyan,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        trip.trailPoints.isNotEmpty ? 'Trip' : 'Spot',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: trip.trailPoints.isNotEmpty
                              ? Colors.amber.shade200
                              : OceanThemeExtension.defaultTokens.cyan,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: OceanThemeExtension.defaultTokens.cyan,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            trip.locationName,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (trip.species.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6.0,
                        runSpacing: 4.0,
                        children: trip.species.map((species) {
                          return Chip(
                            label: Text(
                              species,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TripReactionButtons(trip: trip),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
