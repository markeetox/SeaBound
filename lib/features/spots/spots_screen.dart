import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../../core/map_layer_config.dart';
import '../../core/navigation_disclaimer.dart';
import '../alerts/alerts_providers.dart';
import '../auth/auth_providers.dart';
import '../map/location_providers.dart';
import '../profile/profile_providers.dart';
import '../trips/trip_model.dart';
import '../trips/trips_providers.dart';
import 'trip_recorder_provider.dart';
import '../map_layers/artificial_reefs_service.dart';
import '../map_layers/gibs_date_service.dart';
import '../map_layers/lupita_service.dart';
import '../map_layers/map_layers_dialog.dart';
import '../map_layers/map_layers_provider.dart';
import '../map_layers/no_fishing_zones_service.dart';
import '../map_layers/tide_providers.dart';
import '../map_layers/tide_service.dart';
import '../map_layers/waves_provider.dart';
import '../map_layers/waves_service.dart';
import '../map_layers/weather_radar_service.dart';
import '../map_layers/weather_time_provider.dart';
import '../map_layers/wind_provider.dart';
import '../map_layers/wind_service.dart';
import '../profile/badge_service.dart';
import 'spot_model.dart';
import 'spots_providers.dart';

enum ViewMode { map, list }

class SpotsScreen extends ConsumerStatefulWidget {
  const SpotsScreen({super.key});

  @override
  ConsumerState<SpotsScreen> createState() => _SpotsScreenState();
}

class _SpotsScreenState extends ConsumerState<SpotsScreen> {
  ViewMode _selectedView = ViewMode.map;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NavigationDisclaimer.showFirstLaunchDialogIfNeeded(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final spotsAsync = ref.watch(allSpotsStreamProvider);

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: spotsAsync.when(
          data: (spots) {
            if (_selectedView == ViewMode.map) {
              return _SpotsMapView(
                spots: spots,
                onToggleView: () {
                  setState(() {
                    _selectedView = ViewMode.list;
                  });
                },
              );
            } else {
              return _SpotsListView(
                spots: spots,
                onToggleView: () {
                  setState(() {
                    _selectedView = ViewMode.map;
                  });
                },
              );
            }
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading spots: $error',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LupitaDetailSheet extends StatelessWidget {
  final LupitaSpot spot;

  const _LupitaDetailSheet({required this.spot});

  @override
  Widget build(BuildContext context) {
    final latStr = spot.latitude.toStringAsFixed(4);
    final lngStr = spot.longitude.toStringAsFixed(4);
    final coordStr = '$latStr, $lngStr';
    final scorePct = (spot.score * 100).round();
    final imageUrl =
        'https://cdn.jsdelivr.net/gh/markeetox/lupita@data/api/v1/img/${spot.speciesId}.png';

    final bite = spot.biteWindow;
    String? biteTimeStr;
    if (bite != null && bite.startTime != null && bite.endTime != null) {
      final startFmt = DateFormat.jm().format(bite.startTime!.toLocal());
      final endFmt = DateFormat.jm().format(bite.endTime!.toLocal());
      biteTimeStr = '$startFmt – $endFmt';
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        'Species: ${spot.speciesId.toUpperCase()} • Confidence: ${spot.confidence}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            // Frameless High-Resolution Large Fish Image Display
            const SizedBox(height: 12),
            Center(
              child: Image.network(
                imageUrl,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.set_meal,
                  size: 80,
                  color: Color(0xFF00E5FF),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Prominent Best Bite Window Card
            if (bite != null) ...[
              Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFF38BDF8), size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'BEST BITE WINDOW',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF38BDF8),
                                  letterSpacing: 1.1,
                                ),
                          ),
                          const Spacer(),
                          if (bite.score > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF34D399).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(bite.score * 100).round()}% MATCH',
                                style: const TextStyle(
                                  color: Color(0xFF34D399),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (biteTimeStr != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          biteTimeStr,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      if (bite.why.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ...bite.why.map((reasonText) => Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 14, color: Color(0xFF38BDF8)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      reasonText,
                                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailMetric(
                          label: 'Habitat Score',
                          value: '$scorePct%',
                          icon: Icons.score,
                        ),
                        _DetailMetric(
                          label: 'Data Coverage',
                          value: '${(spot.dataCoverage * 100).round()}%',
                          icon: Icons.equalizer,
                        ),
                      ],
                    ),
                    if (spot.seaSummary != null) ...[
                      const Divider(height: 24),
                      Text(
                        'Sea Conditions: ${spot.seaSummary}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Habitat Match Reasons:',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: spot.reasons.length,
                itemBuilder: (context, index) {
                  final reason = spot.reasons[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 3, right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: OceanThemeExtension.defaultTokens.cyan.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            reason.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: OceanThemeExtension.defaultTokens.cyan,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            reason.text,
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location: $coordStr',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: coordStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coordinates copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotsMapView extends ConsumerStatefulWidget {
  final List<Spot> spots;
  final VoidCallback onToggleView;

  const _SpotsMapView({
    required this.spots,
    required this.onToggleView,
  });

  @override
  ConsumerState<_SpotsMapView> createState() => _SpotsMapViewState();
}

class _SpotsMapViewState extends ConsumerState<_SpotsMapView> {
  final MapController _mapController = MapController();
  LatLngBounds? _currentBounds;
  double _currentZoom = 9.0;
  bool _isLocating = false;
  bool _isFollowUserLocation = false;
  bool _isLegendExpanded = false;

  Timer? _wavesDebounceTimer;
  List<WavePointData>? _wavesData;

  Timer? _reefsDebounceTimer;
  List<ArtificialReefPoint>? _reefsData;
  String? _reefsError;

  Timer? _noFishingDebounceTimer;
  List<NoFishingZone>? _noFishingZonesData;
  String? _noFishingZonesError;

  Timer? _animationTimer;
  int _animationFrameIndex = 0;

  void _syncAnimationTimer(bool isAnimating, int totalFrames) {
    if (isAnimating && totalFrames > 0) {
      if (_animationTimer == null || !_animationTimer!.isActive) {
        _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          if (!mounted) return;
          setState(() {
            _animationFrameIndex = (_animationFrameIndex + 1) % totalFrames;
          });
        });
      }
    } else {
      _animationTimer?.cancel();
      _animationTimer = null;
    }
  }

  @override
  void dispose() {
    _wavesDebounceTimer?.cancel();
    _reefsDebounceTimer?.cancel();
    _noFishingDebounceTimer?.cancel();
    _animationTimer?.cancel();
    super.dispose();
  }

  void _showAddOptionSheet() {
    final tripState = ref.read(tripRecorderProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: OceanThemeExtension.defaultTokens.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add to Map',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: OceanThemeExtension.defaultTokens.cyan,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push('/spots/add');
                  },
                  icon: const Icon(Icons.pin_drop, size: 24),
                  label: const Text(
                    'Secret Spot',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: tripState.isRecording
                        ? Colors.amber.shade700
                        : const Color(0xFFD1142A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    if (tripState.isRecording) {
                      _showSaveTripDialog();
                    } else {
                      ref.read(tripRecorderProvider.notifier).startRecording();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Trip recording started! Moving will trace your path.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    tripState.isRecording ? Icons.stop_circle : Icons.directions_boat,
                    size: 24,
                  ),
                  label: Text(
                    tripState.isRecording ? 'End Recorded Trip' : 'Start Trip Recording',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSaveTripDialog() {
    final tripState = ref.read(tripRecorderProvider);
    final points = tripState.latLngPoints;

    final nameController = TextEditingController(text: 'My Boat Trip');
    final descController = TextEditingController();
    final speciesController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: OceanThemeExtension.defaultTokens.surface,
          title: const Text(
            'Save Recorded Trip',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Recorded ${points.length} GPS points along your path.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: speciesController,
                  decoration: const InputDecoration(
                    labelText: 'Target Species (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(tripRecorderProvider.notifier).reset();
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Discard', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                final authUser = ref.read(authStateProvider).asData?.value;

                final startPoint = points.isNotEmpty
                    ? points.first
                    : (ref.read(userPositionStreamProvider).asData?.value != null
                        ? LatLng(
                            ref.read(userPositionStreamProvider).asData!.value.latitude,
                            ref.read(userPositionStreamProvider).asData!.value.longitude,
                          )
                        : const LatLng(25.7617, -80.1918));

                final speciesList = speciesController.text
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final trailMaps = points
                    .map((p) => {'lat': p.latitude, 'lng': p.longitude})
                    .toList();

                final trip = Trip(
                  id: '',
                  userId: authUser?.uid ?? '',
                  title: nameController.text.trim().isEmpty
                      ? 'My Boat Trip'
                      : nameController.text.trim(),
                  date: DateTime.now(),
                  locationName: '${startPoint.latitude.toStringAsFixed(4)}, ${startPoint.longitude.toStringAsFixed(4)}',
                  species: speciesList,
                  notes: descController.text.trim(),
                  trailPoints: trailMaps,
                );

                final repo = ref.read(tripsRepositoryProvider);
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);

                await repo.createTrip(trip);
                ref.read(tripRecorderProvider.notifier).stopRecording();

                if (mounted) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Recorded Trip saved to Fishing Trips!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Save Trip'),
            ),
          ],
        );
      },
    );
  }

  void _openLayersDialog() {
    showDialog(
      context: context,
      builder: (context) => const MapLayersDialog(),
    );
  }

  void _showTidePredictionDialog(TideStation station) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return _TidePredictionDialog(station: station);
      },
    );
  }

  void _showWaveDetailSheet(WavePointData point, int hourOffset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _WaveDetailSheet(point: point, hourOffset: hourOffset),
    );
  }

  void _showReefDetailSheet(ArtificialReefPoint reef) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _ReefDetailSheet(reef: reef),
    );
  }

  void _showWindDetailSheet(NdbcStationObs station) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _NdbcDetailSheet(station: station),
    );
  }

  void _showLupitaSpotDetailSheet(LupitaSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => _LupitaDetailSheet(spot: spot),
    );
  }

  void _fetchWavesForBounds(LatLngBounds bounds) {
    _wavesDebounceTimer?.cancel();
    _wavesDebounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      final activeLayers = ref.read(activeMapLayersProvider);
      if (!activeLayers.contains(MapLayerConfig.wavesId)) return;

      if (_currentZoom < 5.0) return;

      try {
        final wavesService = ref.read(wavesServiceProvider);
        final data = await wavesService.fetchGridWaves(
          minLat: bounds.south,
          maxLat: bounds.north,
          minLng: bounds.west,
          maxLng: bounds.east,
        );

        if (mounted) {
          setState(() {
            _wavesData = data;
          });
        }
      } catch (_) {}
    });
  }

  void _fetchReefsForBounds(LatLngBounds bounds) {
    _reefsDebounceTimer?.cancel();
    _reefsDebounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      final activeLayers = ref.read(activeMapLayersProvider);
      if (!activeLayers.contains(MapLayerConfig.artificialReefsId)) return;

      if (_currentZoom < 7.0) return;

      setState(() {
        _reefsError = null;
      });

      try {
        final reefsService = ref.read(artificialReefsServiceProvider);
        final points = await reefsService.fetchReefsInBounds(
          minLat: bounds.south,
          maxLat: bounds.north,
          minLng: bounds.west,
          maxLng: bounds.east,
        );

        if (mounted) {
          setState(() {
            _reefsData = points;
            _reefsError = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _reefsError = e.toString().replaceAll('Exception: ', '');
          });
        }
      }
    });
  }

  void _fetchNoFishingZonesForBounds(LatLngBounds bounds) {
    _noFishingDebounceTimer?.cancel();
    _noFishingDebounceTimer = Timer(const Duration(milliseconds: 800), () async {
      if (!mounted) return;

      final activeLayers = ref.read(activeMapLayersProvider);
      if (!activeLayers.contains(MapLayerConfig.noFishingZonesId)) return;

      setState(() {
        _noFishingZonesError = null;
      });

      try {
        final service = ref.read(noFishingZonesServiceProvider);
        final zones = await service.fetchZonesInBounds(
          minLat: bounds.south,
          maxLat: bounds.north,
          minLng: bounds.west,
          maxLng: bounds.east,
        );

        if (mounted) {
          setState(() {
            _noFishingZonesData = zones;
            _noFishingZonesError = null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _noFishingZonesError = e.toString().replaceAll('Exception: ', '');
          });
        }
      }
    });
  }

  Future<void> _toggleFollowLocation() async {
    if (_isFollowUserLocation) {
      setState(() {
        _isFollowUserLocation = false;
      });
    } else {
      setState(() {
        _isFollowUserLocation = true;
      });
      await _centerOnMyLocation();
    }
  }

  Future<void> _centerOnMyLocation() async {
    setState(() {
      _isLocating = true;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      final userLatLng = LatLng(position.latitude, position.longitude);

      final targetZoom = _mapController.camera.zoom < 10.0 ? 13.0 : _mapController.camera.zoom;
      _mapController.move(userLatLng, targetZoom);

      final result = await ref.read(badgeServiceProvider).onMyLocationTapped();
      if (mounted) {
        showBadgeUnlocks(context, result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Color _getWaveColor(double waveHeightFt) {
    if (waveHeightFt < 2.0) {
      return Colors.green.shade600;
    } else if (waveHeightFt < 4.0) {
      return Colors.amber.shade700;
    } else if (waveHeightFt < 6.0) {
      return Colors.orange.shade800;
    } else {
      return Colors.red.shade700;
    }
  }

  Color _getWindColor(double? mph) {
    if (mph == null) return Colors.blueGrey;
    if (mph < 10.0) {
      return Colors.green.shade600;
    } else if (mph < 18.0) {
      return Colors.amber.shade700;
    } else if (mph < 25.0) {
      return Colors.orange.shade800;
    } else {
      return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userDoc = ref.watch(userDocStreamProvider).asData?.value;
    final avatarId = userDoc?['avatarId'] as String?;
    final userBgHex = userDoc?['avatarBgColor'] as String?;
    final userBgVal = userBgHex != null && userBgHex.startsWith('#')
        ? int.tryParse(userBgHex.replaceFirst('#', '0xFF'))
        : null;
    final userPointerColor = userBgVal != null ? Color(userBgVal) : Theme.of(context).colorScheme.primary;

    final activeLayers = ref.watch(activeMapLayersProvider);
    final tideStationsAsync = ref.watch(tideStationsProvider);
    final userPositionAsync = ref.watch(userPositionStreamProvider);
    final alertsState = ref.watch(alertsNotifierProvider);
    final weatherTime = ref.watch(weatherTimeProvider);
    final waveHourOffset = weatherTime.hourOffset;

    final sstDateAsync = ref.watch(sstDateProvider);
    final chlorophyllDateAsync = ref.watch(chlorophyllDateProvider);

    final showArtificialReefs = activeLayers.contains(MapLayerConfig.artificialReefsId);
    final showSst = activeLayers.contains(MapLayerConfig.seaTemperatureId);
    final showChlorophyll = activeLayers.contains(MapLayerConfig.chlorophyllId);
    final showTides = activeLayers.contains(MapLayerConfig.tideStationsId);
    final showWaves = activeLayers.contains(MapLayerConfig.wavesId);
    final showDepth = activeLayers.contains(MapLayerConfig.depthBathymetryId);
    final showSoundings = activeLayers.contains(MapLayerConfig.depthNumbersId);
    final showRadar = activeLayers.contains(MapLayerConfig.weatherRadarId);
    final showNoFishingZones = activeLayers.contains(MapLayerConfig.noFishingZonesId);
    final radarDataAsync = showRadar ? ref.watch(radarFramesProvider) : null;
    final showFishSpots = activeLayers.contains('fish_spots');
    final showWindObs = activeLayers.contains(MapLayerConfig.windObsId);
    final showLupita = activeLayers.contains(MapLayerConfig.lupitaFishId);
    final lupitaSpots = showLupita ? ref.watch(selectedLupitaSpeciesSpotsProvider) : <LupitaSpot>[];
    final lupitaDataAsync = showLupita ? ref.watch(lupitaDataProvider) : null;
    final selectedLupitaId = showLupita ? ref.watch(selectedLupitaSpeciesIdProvider) : null;

    final ndbcStationsAsync = ref.watch(ndbcStationsProvider);

    final activeCount = activeLayers.length;

    final initialCenter = widget.spots.isNotEmpty
        ? LatLng(widget.spots.first.latitude, widget.spots.first.longitude)
        : const LatLng(25.7617, -80.1918);

    ref.listen<Set<String>>(activeMapLayersProvider, (prev, next) {
      if (_currentBounds != null) {
        if (next.contains(MapLayerConfig.wavesId)) {
          _fetchWavesForBounds(_currentBounds!);
        }
        if (next.contains(MapLayerConfig.artificialReefsId)) {
          _fetchReefsForBounds(_currentBounds!);
        }
        if (next.contains(MapLayerConfig.noFishingZonesId)) {
          _fetchNoFishingZonesForBounds(_currentBounds!);
        }
      }
    });

    ref.listen<AsyncValue<List<TideStation>>>(tideStationsProvider, (prev, next) {
      if (next.hasError && showTides) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load tide stations: ${next.error}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    ref.listen<AsyncValue<Position>>(userPositionStreamProvider, (prev, next) {
      final pos = next.asData?.value;
      if (pos != null && _isFollowUserLocation) {
        _mapController.move(
          LatLng(pos.latitude, pos.longitude),
          _mapController.camera.zoom,
        );
      }
    });

    final tripRecorderState = ref.watch(tripRecorderProvider);

    final Position? userPos = userPositionAsync.asData?.value;
    final LatLng? userLatLng =
        userPos != null ? LatLng(userPos.latitude, userPos.longitude) : null;

    final mostSevereAlert =
        alertsState.alerts.isNotEmpty ? alertsState.alerts.first : null;

    final isPhoneScreen = MediaQuery.of(context).size.width < 600;
    final shouldShowLegendContent = !isPhoneScreen || _isLegendExpanded;

    final hasAnyLegend = showDepth || showWaves || showSst || showChlorophyll || showArtificialReefs || showWindObs;

    return Stack(
      children: [
        // Map Fills Whole Screen
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: widget.spots.isNotEmpty ? 10.0 : 9.0,
            maxZoom: 20.0,
            onMapReady: () {
              final bounds = _mapController.camera.visibleBounds;
              setState(() {
                _currentBounds = bounds;
                _currentZoom = _mapController.camera.zoom;
              });
              if (showWaves) _fetchWavesForBounds(bounds);
              if (showArtificialReefs) _fetchReefsForBounds(bounds);
              if (showNoFishingZones) _fetchNoFishingZonesForBounds(bounds);
            },
            onPositionChanged: (position, hasGesture) {
              setState(() {
                _currentBounds = position.visibleBounds;
                _currentZoom = position.zoom;
                if (hasGesture && _isFollowUserLocation) {
                  _isFollowUserLocation = false;
                }
              });
              if (showWaves) _fetchWavesForBounds(position.visibleBounds);
              if (showArtificialReefs) _fetchReefsForBounds(position.visibleBounds);
              if (showNoFishingZones) _fetchNoFishingZonesForBounds(position.visibleBounds);
            },
          ),
          children: [
            // Base Tile Layer
            TileLayer(
              urlTemplate: MapLayerConfig.openStreetMapTileUrl,
              userAgentPackageName: 'com.onerevamp.seabound',
              maxNativeZoom: 19,
              maxZoom: 20,
              errorTileCallback: (_, _, _) {},
            ),

            // NASA GIBS Sea Surface Temperature Layer
            if (showSst)
              sstDateAsync.when(
                data: (dateStr) {
                  final tileUrl = MapLayerConfig.gibsWmtsTileUrl(
                    layerIdentifier: MapLayerConfig.gibsSstLayerIdentifier,
                    dateStr: dateStr,
                    tileMatrixSet: MapLayerConfig.gibsSstTileMatrixSet,
                  );
                  return TileLayer(
                    urlTemplate: tileUrl,
                    userAgentPackageName: 'com.onerevamp.seabound',
                    maxNativeZoom: 7,
                    tileProvider: NetworkTileProvider(),
                    tileDisplay: const TileDisplay.instantaneous(opacity: 0.7),
                    errorTileCallback: (_, _, _) {},
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),

            // NASA GIBS Chlorophyll-A Layer
            if (showChlorophyll)
              chlorophyllDateAsync.when(
                data: (dateStr) {
                  final tileUrl = MapLayerConfig.gibsWmtsTileUrl(
                    layerIdentifier:
                        MapLayerConfig.gibsChlorophyllLayerIdentifier,
                    dateStr: dateStr,
                    tileMatrixSet: MapLayerConfig.gibsChlorophyllTileMatrixSet,
                  );
                  return TileLayer(
                    urlTemplate: tileUrl,
                    userAgentPackageName: 'com.onerevamp.seabound',
                    maxNativeZoom: 7,
                    tileProvider: NetworkTileProvider(),
                    tileDisplay: const TileDisplay.instantaneous(opacity: 0.7),
                    errorTileCallback: (_, _, _) {},
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, st) => const SizedBox.shrink(),
              ),


            // Depth & Bathymetry Layer (GEBCO colour-shaded WMS + OpenSeaMap seamarks)
            if (showDepth) ...[
              TileLayer(
                wmsOptions: WMSTileLayerOptions(
                  baseUrl: MapLayerConfig.gebcoWmsUrl,
                  layers: [MapLayerConfig.gebcoLayerName],
                ),
                maxNativeZoom: 18,
                maxZoom: 20,
                tileProvider: NetworkTileProvider(),
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.7),
                errorTileCallback: (_, _, _) {},
              ),
              TileLayer(
                urlTemplate: MapLayerConfig.openSeaMapTileUrl,
                userAgentPackageName: 'com.onerevamp.seabound',
                maxNativeZoom: 18,
                maxZoom: 20,
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.8),
                errorTileCallback: (_, _, _) {},
              ),
            ],

            // No-Fishing / Protected Marine Zones Polygon Layer
            if (showNoFishingZones && _noFishingZonesData != null)
              PolygonLayer(
                polygons: [
                  for (final zone in _noFishingZonesData!)
                    for (final ring in zone.polygonRings)
                      Polygon(
                        points: ring,
                        color: const Color(0x55D1142A),
                        borderColor: const Color(0xFFD1142A),
                        borderStrokeWidth: 2.0,
                      ),
                ],
              ),

            // Depth Numbers (NOAA Soundings) WMS Layer
            if (showSoundings)
              TileLayer(
                wmsOptions: WMSTileLayerOptions(
                  baseUrl: MapLayerConfig.noaaChartDisplayWmsUrl,
                  layers: MapLayerConfig.noaaSoundingsLayerName.split(','),
                  transparent: true,
                  format: 'image/png',
                ),
                maxNativeZoom: 18,
                maxZoom: 20,
                tileProvider: NetworkTileProvider(),
                tileDisplay: const TileDisplay.instantaneous(opacity: 0.85),
                errorTileCallback: (_, _, _) {},
              ),

            // Weather Radar Layer with Smoothed Contours & Animated Radar Frame Swapping
            if (showRadar && radarDataAsync != null)
              radarDataAsync.when(
                data: (radarResp) {
                  final frames = radarResp.allFrames;
                  if (frames.isEmpty) return const SizedBox.shrink();

                  _syncAnimationTimer(weatherTime.isAnimating, frames.length);

                  String? tileUrl;
                  if (weatherTime.isAnimating) {
                    final frameIdx = _animationFrameIndex % frames.length;
                    tileUrl = radarResp.getTileUrlForFrameIndex(
                      frameIdx,
                      tileSize: 512,
                      smooth: true,
                    );
                  } else {
                    tileUrl = radarResp.getTileUrlForOffset(
                      weatherTime.hourOffset,
                      tileSize: 512,
                      smooth: true,
                    );
                  }

                  if (tileUrl == null) return const SizedBox.shrink();

                  return TileLayer(
                    key: ValueKey(tileUrl),
                    urlTemplate: tileUrl,
                    tileDimension: 512,
                    zoomOffset: -1,
                    maxNativeZoom: 12,
                    maxZoom: 20,
                    tileProvider: NetworkTileProvider(),
                    tileDisplay: const TileDisplay.instantaneous(opacity: 0.65),
                    errorTileCallback: (_, _, _) {},
                  );
                },
                loading: () => TileLayer(
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl: MapLayerConfig.noaaNowCoastRadarWmsUrl,
                    layers: [MapLayerConfig.noaaRadarLayerName],
                    transparent: true,
                    format: 'image/png',
                  ),
                  tileProvider: NetworkTileProvider(),
                  tileDisplay: const TileDisplay.instantaneous(opacity: 0.6),
                ),
                error: (e, st) => TileLayer(
                  wmsOptions: WMSTileLayerOptions(
                    baseUrl: MapLayerConfig.noaaNowCoastRadarWmsUrl,
                    layers: [MapLayerConfig.noaaRadarLayerName],
                    transparent: true,
                    format: 'image/png',
                  ),
                  tileProvider: NetworkTileProvider(),
                  tileDisplay: const TileDisplay.instantaneous(opacity: 0.6),
                ),
              ),

            // FWC Artificial Reefs Marker Layer
            if (showArtificialReefs && _reefsData != null && _currentZoom >= 7.0)
              MarkerLayer(
                markers: _reefsData!.map((reef) {
                  return Marker(
                    point: LatLng(reef.latitude, reef.longitude),
                    width: 28.0,
                    height: 28.0,
                    child: GestureDetector(
                      onTap: () => _showReefDetailSheet(reef),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.brown.shade700,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.anchor,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // NOAA NDBC Wind & Buoy Station Markers Layer
            if (showWindObs)
              ndbcStationsAsync.when(
                data: (stations) {
                  final visibleStations = stations.where((s) {
                    if (_currentBounds == null) return true;
                    return _currentBounds!.contains(LatLng(s.latitude, s.longitude));
                  }).toList();

                  return MarkerLayer(
                    markers: visibleStations.map((station) {
                      final color = _getWindColor(station.windSpeedMph);
                      final dirRad = station.windDirectionDeg != null
                          ? (station.windDirectionDeg! * (3.1415926535 / 180.0))
                          : 0.0;
                      final speedLabel = station.windSpeedMph != null
                          ? '${station.windSpeedMph!.toStringAsFixed(0)}mph'
                          : 'Buoy';

                      return Marker(
                        point: LatLng(station.latitude, station.longitude),
                        width: 44.0,
                        height: 44.0,
                        child: GestureDetector(
                          onTap: () => _showWindDetailSheet(station),
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (station.windDirectionDeg != null)
                                  Transform.rotate(
                                    angle: dirRad,
                                    child: const Icon(
                                      Icons.arrow_upward,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                  ),
                                Text(
                                  speedLabel,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),

            // Waves Grid Markers Layer
            if (showWaves && _wavesData != null && _currentZoom >= 5.0)
              MarkerLayer(
                markers: _wavesData!.map((point) {
                  final entry = point.getForOffset(waveHourOffset);
                  final waveColor = _getWaveColor(entry.waveHeightFt);
                  final directionRad = entry.waveDirectionDeg != null
                      ? (entry.waveDirectionDeg! * (3.1415926535 / 180.0))
                      : 0.0;

                  return Marker(
                    point: LatLng(point.latitude, point.longitude),
                    width: 50.0,
                    height: 50.0,
                    child: GestureDetector(
                      onTap: () => _showWaveDetailSheet(point, waveHourOffset),
                      child: Container(
                        decoration: BoxDecoration(
                          color: waveColor.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 3,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (entry.waveDirectionDeg != null)
                              Transform.rotate(
                                angle: directionRad,
                                child: const Icon(
                                  Icons.arrow_upward,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            Text(
                              '${entry.waveHeightFt.toStringAsFixed(1)}ft',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // User Position Accuracy Circle & Marker Layer
            if (userLatLng != null) ...[
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: userLatLng,
                    radius: (userPos?.accuracy ?? 15.0).clamp(10.0, 100.0),
                    useRadiusInMeter: true,
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderColor: Colors.blue.withValues(alpha: 0.6),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: userLatLng,
                    width: 38.0,
                    height: 38.0,
                    child: Container(
                      key: const ValueKey('user_avatar_location_pointer'),
                      padding: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: userPointerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.0),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: avatarId != null && avatarId.isNotEmpty
                          ? Image.asset(
                              'assets/avatars/$avatarId.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person,
                                size: 22,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 22,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ],
              ),
            ],

            // Tide Stations Marker Layer
            if (showTides)
              tideStationsAsync.when(
                data: (stations) {
                  final visibleStations = stations.where((station) {
                    if (_currentBounds == null) return true;
                    final point = LatLng(station.lat, station.lng);
                    return _currentBounds!.contains(point);
                  }).toList();

                  return MarkerLayer(
                    markers: visibleStations.map((station) {
                      return Marker(
                        point: LatLng(station.lat, station.lng),
                        width: 32.0,
                        height: 32.0,
                        child: GestureDetector(
                          onTap: () => _showTidePredictionDialog(station),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.waves,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),

            // Polyline Layer for Live Recorded Trip Trail
            if (tripRecorderState.isRecording && tripRecorderState.latLngPoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: tripRecorderState.latLngPoints,
                    color: Colors.black,
                    strokeWidth: 4.0,
                  ),
                ],
              ),

            // Lupita Fish Habitat Spot Markers Layer
            if (showLupita && lupitaSpots.isNotEmpty)
              MarkerLayer(
                markers: lupitaSpots.map((lSpot) {
                  final scorePct = (lSpot.score * 100).round();
                  return Marker(
                    point: LatLng(lSpot.latitude, lSpot.longitude),
                    width: 48.0,
                    height: 48.0,
                    child: GestureDetector(
                      onTap: () => _showLupitaSpotDetailSheet(lSpot),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1B2D),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: lSpot.score >= 0.75
                                ? const Color(0xFF34D399)
                                : (lSpot.score >= 0.5 ? const Color(0xFFFBBF24) : Colors.orange),
                            width: 2.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.set_meal,
                              size: 16,
                              color: Color(0xFF00E5FF),
                            ),
                            Text(
                              '$scorePct%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

            // Community Spot Markers Layer
            if (showFishSpots)
              MarkerLayer(
                markers: widget.spots.map((spot) {
                  return Marker(
                    point: LatLng(spot.latitude, spot.longitude),
                    width: 44.0,
                    height: 44.0,
                    child: GestureDetector(
                      onTap: () {
                        context.push('/spots/${spot.id}');
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: userPointerColor,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.place,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

          ],
        ),

        // TOP CENTER DROPDOWN BAR FOR LUPITA SPECIES FILTER
        if (showLupita && lupitaDataAsync != null)
          Positioned(
            top: (hasAnyLegend || mostSevereAlert != null || showNoFishingZones)
                ? (shouldShowLegendContent ? 180 : 110)
                : 12,
            left: 16,
            right: 80,
            child: SafeArea(
              child: lupitaDataAsync.when(
                data: (lData) {
                  final speciesList = lData.species;
                  return Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: OceanThemeExtension.defaultTokens.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: OceanThemeExtension.defaultTokens.cyan, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        key: const ValueKey('lupita_species_dropdown'),
                        isExpanded: true,
                        dropdownColor: OceanThemeExtension.defaultTokens.surface,
                        value: selectedLupitaId,
                        hint: const Row(
                          children: [
                            Icon(Icons.set_meal, color: Color(0xFF00E5FF), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Lupita: All Species',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Lupita: All Species',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...speciesList.map((s) {
                            return DropdownMenuItem<String?>(
                              value: s.id,
                              child: Row(
                                children: [
                                  Image.network(
                                    s.imageUrl,
                                    width: 28,
                                    height: 20,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.set_meal,
                                      color: OceanThemeExtension.defaultTokens.cyan,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${s.name} (${s.spotCount} spots)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          ref
                              .read(selectedLupitaSpeciesIdProvider.notifier)
                              .selectSpecies(val);
                        },
                      ),
                    ),
                  );
                },
                loading: () => Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: OceanThemeExtension.defaultTokens.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Loading Lupita Fish Data...', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),
          ),

        // TOP-RIGHT CONTROLS OVERLAY: Layers, Location, and Add Pointer Controls with Chrome Gradient Border
        Positioned(
          top: 8,
          right: 16,
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Layers Button
                ChromeBorderContainer(
                  borderRadius: BorderRadius.circular(24),
                  borderWidth: 2,
                  backgroundColor: OceanThemeExtension.defaultTokens.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                  child: Tooltip(
                    message: 'Layers',
                    child: InkWell(
                      onTap: _openLayersDialog,
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(Icons.layers_outlined, size: 22, color: Colors.white),
                            if (activeCount > 0)
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00E5FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$activeCount',
                                    style: const TextStyle(
                                      color: Color(0xFF001018),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
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
                const SizedBox(height: 8),

                // My Location Toggle Button
                ChromeBorderContainer(
                  borderRadius: BorderRadius.circular(24),
                  borderWidth: 2,
                  backgroundColor: _isFollowUserLocation
                      ? OceanThemeExtension.defaultTokens.cyan.withValues(alpha: 0.3)
                      : OceanThemeExtension.defaultTokens.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                  child: Tooltip(
                    message: _isFollowUserLocation ? 'Tracking Location (On)' : 'Center Location',
                    child: InkWell(
                      key: const ValueKey('locate_toggle_button'),
                      onTap: _isLocating ? null : _toggleFollowLocation,
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: _isLocating
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _isFollowUserLocation ? Icons.my_location : Icons.location_searching,
                                  size: 22,
                                  color: _isFollowUserLocation
                                      ? OceanThemeExtension.defaultTokens.cyan
                                      : Colors.white,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Add Pointer / Add Option Button
                ChromeBorderContainer(
                  borderRadius: BorderRadius.circular(24),
                  borderWidth: 2,
                  backgroundColor: tripRecorderState.isRecording
                      ? Colors.amber.shade700
                      : const Color(0xFFD1142A),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                  child: Tooltip(
                    message: tripRecorderState.isRecording ? 'Recording Trip...' : 'Add Spot / Trip',
                    child: InkWell(
                      onTap: _showAddOptionSheet,
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            tripRecorderState.isRecording ? Icons.directions_boat : Icons.add_location_alt,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // TOP-LEFT STACK: Map Legend and Active Warning Banners
        Positioned(
          top: 8,
          left: 16,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Unified Collapsible Legend Panel
                if (hasAnyLegend)
                  GestureDetector(
                    onTap: () {
                      if (isPhoneScreen) {
                        setState(() {
                          _isLegendExpanded = !_isLegendExpanded;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      constraints: const BoxConstraints(maxWidth: 220),
                      decoration: BoxDecoration(
                        color: OceanThemeExtension.defaultTokens.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Map Legends',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isPhoneScreen) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  _isLegendExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          if (shouldShowLegendContent) ...[
                            const SizedBox(height: 8),

                            // Artificial Reefs & Habitat Info
                            if (showArtificialReefs) ...[
                              const Text(
                                'Artificial Reefs',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                MapLayerConfig.fwcStructureInfoText,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 8,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Sea Temperature Legend
                            if (showSst) ...[
                              const Text(
                                'Sea temperature',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              sstDateAsync.when(
                                data: (d) => Text(
                                  'Image date: ${GibsDateService.formatDisplayDate(d)}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 8),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (e, st) => const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 4),
                              Image.network(
                                MapLayerConfig.gibsSstLegendUrl,
                                height: 16,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Shows ocean conditions that often concentrate fish, such as temperature breaks and color changes. It does not show where fish are. Clouds can leave gaps.',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8,
                                    fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Chlorophyll Legend
                            if (showChlorophyll) ...[
                              const Text(
                                'Chlorophyll',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              chlorophyllDateAsync.when(
                                data: (d) => Text(
                                  'Image date: ${GibsDateService.formatDisplayDate(d)}',
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 8),
                                ),
                                loading: () => const SizedBox.shrink(),
                                error: (e, st) => const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 4),
                              Image.network(
                                MapLayerConfig.gibsChlorophyllLegendUrl,
                                height: 16,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox.shrink(),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Shows ocean conditions that often concentrate fish, such as temperature breaks and color changes. It does not show where fish are. Clouds can leave gaps.',
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 8,
                                    fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Depth Legend
                            if (showDepth) ...[
                              const Text(
                                'Elevation / Depth',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: 110,
                                height: 8,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF000055),
                                      Color(0xFF0066CC),
                                      Color(0xFF66CCFF),
                                      Color(0xFF009933),
                                      Color(0xFF996633),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              const SizedBox(
                                width: 110,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Deep',
                                        style: TextStyle(
                                            color: Colors.white54, fontSize: 8)),
                                    Text('High',
                                        style: TextStyle(
                                            color: Colors.white54, fontSize: 8)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Waves Legend
                            if (showWaves) ...[
                              const Text(
                                'Wave Height (ft)',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  _LegendBox(
                                      color: Colors.green.shade600, label: '<2'),
                                  const SizedBox(width: 3),
                                  _LegendBox(
                                      color: Colors.amber.shade700, label: '2-4'),
                                  const SizedBox(width: 3),
                                  _LegendBox(
                                      color: Colors.orange.shade800, label: '4-6'),
                                  const SizedBox(width: 3),
                                  _LegendBox(
                                      color: Colors.red.shade700, label: '>6'),
                                ],
                              ),
                        const SizedBox(height: 8),
                      ],

                      // Wind Speed Legend
                      if (showWindObs) ...[
                        const Text(
                          'Wind Speed (mph)',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _LegendBox(
                                color: Colors.green.shade600, label: '<10'),
                            const SizedBox(width: 3),
                            _LegendBox(
                                color: Colors.amber.shade700, label: '10-18'),
                            const SizedBox(width: 3),
                            _LegendBox(
                                color: Colors.orange.shade800, label: '18-25'),
                            const SizedBox(width: 3),
                            _LegendBox(
                                color: Colors.red.shade700, label: '>25'),
                          ],
                        ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),

                // Slim Weather Alert Banner directly under Legend
                if (mostSevereAlert != null) ...[
                  if (hasAnyLegend) const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      context.go('/alerts');
                    },
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 220),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _alertSeverityColor(mostSevereAlert.severity),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${mostSevereAlert.event} (${mostSevereAlert.severity})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: Colors.white, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],


                // Active No-Fishing Zone Liability Disclaimer Banner
                if (showNoFishingZones) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1142A),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.do_not_disturb_on_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'NO-FISHING ZONES ACTIVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Boundaries for reference only. Fishermen are strictly responsible for verifying official FWC & NOAA rules. Seabound accepts no liability for fishing in restricted zones.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // No-Fishing Zones Error Banner directly under Legend/Alerts
                if (showNoFishingZones && _noFishingZonesError != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Couldn't load zone data",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final bounds = _currentBounds ?? _mapController.camera.visibleBounds;
                            _fetchNoFishingZonesForBounds(bounds);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Artificial Reefs Error Banner directly under Legend/Alerts
                if (showArtificialReefs && _reefsError != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 220),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Couldn't load reef data",
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final bounds = _currentBounds ?? _mapController.camera.visibleBounds;
                            _fetchReefsForBounds(bounds);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // UNIFIED WEATHER FORECAST & TIME CONTROL BAR
        if (showWaves || showRadar || showWindObs)
          Positioned(
            bottom: 110,
            left: 16,
            right: 16,
            child: Center(
              child: showRadar && radarDataAsync != null
                  ? radarDataAsync.when(
                      data: (radarResp) {
                        final frames = radarResp.allFrames;
                        if (frames.isEmpty) return const SizedBox.shrink();

                        final liveIdx = (radarResp.past.length - 1).clamp(0, frames.length - 1);
                        final activeIdx = _animationFrameIndex.clamp(0, frames.length - 1);
                        final activeFrame = frames[activeIdx];
                        final liveFrame = frames[liveIdx];

                        final activeTime = DateFormat.jm().format(
                          DateTime.fromMillisecondsSinceEpoch(activeFrame.time * 1000),
                        );
                        final diffMinutes = ((activeFrame.time - liveFrame.time) / 60).round();

                        String pillLabel;
                        if (diffMinutes < 0) {
                          pillLabel = 'PAST ${diffMinutes}m • $activeTime';
                        } else if (diffMinutes == 0) {
                          pillLabel = 'LIVE OBS • $activeTime';
                        } else {
                          pillLabel = 'FORECAST +${diffMinutes}m • $activeTime';
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Synchronized Timestamp Indicator Pill
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: diffMinutes == 0
                                    ? const Color(0xFF00E5FF).withValues(alpha: 0.95)
                                    : const Color(0xFFFF9100).withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    diffMinutes == 0 ? Icons.sensors : Icons.schedule,
                                    size: 14,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    pillLabel,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Interactive Timeline Slider Control Bar
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                              decoration: BoxDecoration(
                                color: OceanThemeExtension.defaultTokens.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white24, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Play / Pause Button
                                  IconButton(
                                    icon: Icon(
                                      weatherTime.isAnimating
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: OceanThemeExtension.defaultTokens.cyan,
                                      size: 26,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                    tooltip: weatherTime.isAnimating ? 'Pause' : 'Play',
                                    onPressed: () {
                                      ref.read(weatherTimeProvider.notifier).toggleAnimation();
                                    },
                                  ),
                                  const SizedBox(width: 4),

                                  // Interactive Time Scrubbing Slider
                                  SizedBox(
                                    width: 170,
                                    child: SliderTheme(
                                      data: SliderThemeData(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                                        activeTrackColor: OceanThemeExtension.defaultTokens.cyan,
                                        inactiveTrackColor: Colors.white24,
                                        thumbColor: OceanThemeExtension.defaultTokens.cyan,
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                      ),
                                      child: Slider(
                                        value: activeIdx.toDouble(),
                                        min: 0.0,
                                        max: (frames.length - 1).toDouble(),
                                        divisions: (frames.length - 1) > 0 ? (frames.length - 1) : 1,
                                        onChanged: (val) {
                                          if (weatherTime.isAnimating) {
                                            ref.read(weatherTimeProvider.notifier).toggleAnimation();
                                          }
                                          final newIdx = val.round();
                                          setState(() {
                                            _animationFrameIndex = newIdx;
                                          });
                                          final hourOffset = ((frames[newIdx].time - liveFrame.time) / 3600).round().clamp(0, 24);
                                          ref.read(weatherTimeProvider.notifier).setHourOffset(hourOffset);
                                          ref.read(selectedWaveHourOffsetProvider.notifier).setHourOffset(hourOffset);
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),

                                  // "LIVE" Quick Jump Button
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      if (weatherTime.isAnimating) {
                                        ref.read(weatherTimeProvider.notifier).toggleAnimation();
                                      }
                                      setState(() {
                                        _animationFrameIndex = liveIdx;
                                      });
                                      ref.read(weatherTimeProvider.notifier).resetToLive();
                                      ref.read(selectedWaveHourOffsetProvider.notifier).setHourOffset(0);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: activeIdx == liveIdx ? const Color(0xFF00E5FF) : Colors.white10,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'LIVE',
                                        style: TextStyle(
                                          color: activeIdx == liveIdx ? Colors.black : Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (e, st) => const SizedBox.shrink(),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Timestamp & Mode Indicator Pill
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: weatherTime.isLive
                                ? const Color(0xFF00E5FF).withValues(alpha: 0.95)
                                : const Color(0xFFFF9100).withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black38,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                weatherTime.isLive ? Icons.sensors : Icons.schedule,
                                size: 14,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                weatherTime.isLive
                                    ? 'LIVE OBS • ${DateFormat.jm().format(weatherTime.validTime)}'
                                    : 'FORECAST +${weatherTime.hourOffset}h • ${DateFormat.yMMMd().add_jm().format(weatherTime.validTime)}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Time Step Controls
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: OceanThemeExtension.defaultTokens.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white24, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _WeatherTimeButton(label: 'Now', offset: 0),
                              _WeatherTimeButton(label: '+1h', offset: 1),
                              _WeatherTimeButton(label: '+3h', offset: 3),
                              _WeatherTimeButton(label: '+6h', offset: 6),
                              _WeatherTimeButton(label: '+12h', offset: 12),
                              _WeatherTimeButton(label: '+24h', offset: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),

        // Merged Copyright & Not For Navigation Disclaimer Pill along bottom edge
        Positioned(
          bottom: 4,
          left: 16,
          right: 16,
          child: Center(
            child: GestureDetector(
              onTap: () => NavigationDisclaimer.showFullDisclaimerDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '© OpenStreetMap, NOAA & FWC • Not for navigation. Tap for details.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _alertSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'extreme':
        return Colors.red.shade900;
      case 'severe':
        return Colors.red.shade700;
      case 'moderate':
        return Colors.orange.shade900;
      case 'minor':
        return Colors.amber.shade900;
      default:
        return Colors.blueGrey.shade800;
    }
  }
}

class _ReefDetailSheet extends StatelessWidget {
  final ArtificialReefPoint reef;

  const _ReefDetailSheet({required this.reef});

  @override
  Widget build(BuildContext context) {
    final latStr = reef.latitude.toStringAsFixed(5);
    final lngStr = reef.longitude.toStringAsFixed(5);
    final coordStr = '$latStr, $lngStr';

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
                Expanded(
                  child: Text(
                    reef.reefName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (reef.primaryMaterial != null) ...[
                      _ReefMetric(
                        label: 'Material / Type',
                        value: reef.primaryMaterial!,
                        icon: Icons.construction,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (reef.waterDepthFt != null) ...[
                      _ReefMetric(
                        label: 'Water Depth',
                        value: '${reef.waterDepthFt!} ft',
                        icon: Icons.water,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (reef.deploymentDate != null) ...[
                      _ReefMetric(
                        label: 'Deployment Date',
                        value: reef.deploymentDate!,
                        icon: Icons.calendar_today,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (reef.countyAgency != null) ...[
                      _ReefMetric(
                        label: 'County / Agency',
                        value: reef.countyAgency!,
                        icon: Icons.account_balance,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ReefMetric(
                          label: 'Coordinates',
                          value: coordStr,
                          icon: Icons.pin_drop,
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: coordStr));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Coordinates copied to clipboard!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              MapLayerConfig.fwcStructureInfoText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReefMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReefMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: OceanThemeExtension.defaultTokens.cyan, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendBox extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendBox({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 9),
        ),
      ],
    );
  }
}

class _WeatherTimeButton extends ConsumerWidget {
  final String label;
  final int offset;

  const _WeatherTimeButton({required this.label, required this.offset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherTime = ref.watch(weatherTimeProvider);
    final isSelected = weatherTime.hourOffset == offset;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          ref.read(weatherTimeProvider.notifier).setHourOffset(offset);
          ref.read(selectedWaveHourOffsetProvider.notifier).setHourOffset(offset);
        },
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _WaveDetailSheet extends StatelessWidget {
  final WavePointData point;
  final int hourOffset;

  const _WaveDetailSheet({required this.point, required this.hourOffset});

  @override
  Widget build(BuildContext context) {
    final currentEntry = point.getForOffset(hourOffset);
    final formattedTime = DateFormat.jm().format(currentEntry.time);

    final compassDir =
        HourlyWaveEntry.degreesToCompass(currentEntry.waveDirectionDeg);

    final next24Entries = point.hourlyEntries.where((e) {
      return e.time.isAfter(currentEntry.time) &&
          e.time.isBefore(currentEntry.time.add(const Duration(hours: 25)));
    }).take(24).toList();

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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wave Conditions ($formattedTime)',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      'Point: ${point.latitude.toStringAsFixed(3)}, ${point.longitude.toStringAsFixed(3)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailMetric(
                          label: 'Wave Height',
                          value:
                              '${currentEntry.waveHeightFt.toStringAsFixed(1)} ft',
                          icon: Icons.water,
                        ),
                        _DetailMetric(
                          label: 'Direction',
                          value: '$compassDir (${currentEntry.waveDirectionDeg?.toStringAsFixed(0)}°)',
                          icon: Icons.explore,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailMetric(
                          label: 'Wave Period',
                          value: currentEntry.wavePeriodSec != null
                              ? '${currentEntry.wavePeriodSec!.toStringAsFixed(1)} s'
                              : 'N/A',
                          icon: Icons.timer_outlined,
                        ),
                        _DetailMetric(
                          label: 'Swell Height',
                          value: currentEntry.swellHeightFt != null
                              ? '${currentEntry.swellHeightFt!.toStringAsFixed(1)} ft'
                              : 'N/A',
                          icon: Icons.waves,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OceanThemeExtension.defaultTokens.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Period: time between waves (longer periods = smooth swell, short = choppy waves).',
                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Next 24-Hour Forecast',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: next24Entries.length,
                itemBuilder: (context, index) {
                  final entry = next24Entries[index];
                  final timeLabel = DateFormat.j().format(entry.time);

                  return Card(
                    margin: const EdgeInsets.only(right: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            timeLabel,
                            style: const TextStyle(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${entry.waveHeightFt.toStringAsFixed(1)} ft',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                          if (entry.wavePeriodSec != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${entry.wavePeriodSec!.toStringAsFixed(0)}s',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NdbcDetailSheet extends StatelessWidget {
  final NdbcStationObs station;

  const _NdbcDetailSheet({required this.station});

  @override
  Widget build(BuildContext context) {
    final latStr = station.latitude.toStringAsFixed(4);
    final lngStr = station.longitude.toStringAsFixed(4);
    final coordStr = '$latStr, $lngStr';
    final timeStr = DateFormat.yMMMd().add_jm().format(station.observationTime.toLocal());
    final compassDir = NdbcStationObs.degreesToCompass(station.windDirectionDeg);

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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOAA NDBC Station ${station.stationId}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      Text(
                        'Observed: $timeStr',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailMetric(
                          label: 'Wind Speed',
                          value: station.windSpeedMph != null
                              ? '${station.windSpeedMph!.toStringAsFixed(1)} mph'
                              : 'N/A',
                          icon: Icons.air,
                        ),
                        _DetailMetric(
                          label: 'Wind Direction',
                          value: station.windDirectionDeg != null
                              ? '$compassDir (${station.windDirectionDeg!.toStringAsFixed(0)}°)'
                              : 'N/A',
                          icon: Icons.explore,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _DetailMetric(
                          label: 'Wind Gusts',
                          value: station.windGustMph != null
                              ? '${station.windGustMph!.toStringAsFixed(1)} mph'
                              : 'N/A',
                          icon: Icons.air,
                        ),
                        _DetailMetric(
                          label: 'Wave Height',
                          value: station.waveHeightFt != null
                              ? '${station.waveHeightFt!.toStringAsFixed(1)} ft'
                              : 'N/A',
                          icon: Icons.waves,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Location: $coordStr',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: coordStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Coordinates copied to clipboard!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: OceanThemeExtension.defaultTokens.cyan, size: 22),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }
}

class _TidePredictionDialog extends ConsumerWidget {
  final TideStation station;

  const _TidePredictionDialog({required this.station});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final predictionsAsync =
        ref.watch(stationPredictionsProvider(station.id));

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.waves,
                color: OceanThemeExtension.defaultTokens.cyan,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  station.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          if (station.state.isNotEmpty)
            Text(
              'Station ID: ${station.id} (${station.state})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
            ),
        ],
      ),
      content: SizedBox(
        width: 320,
        child: predictionsAsync.when(
          data: (predictions) {
            if (predictions.isEmpty) {
              return const Text('No tide predictions available for today.');
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's High / Low Tides:",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 12),
                ...predictions.map((p) {
                  final isHigh = p.type.toUpperCase() == 'H';
                  final timeStr = DateFormat.jm().format(p.time);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isHigh
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                              color: isHigh
                                  ? OceanThemeExtension.defaultTokens.cyan
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isHigh ? 'High Tide' : 'Low Tide',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        Text('$timeStr (${p.value.toStringAsFixed(1)} ft)'),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Text(
            'Unable to fetch tide predictions: $error',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _SpotsListView extends StatelessWidget {
  final List<Spot> spots;
  final VoidCallback onToggleView;

  const _SpotsListView({
    required this.spots,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.place_outlined,
                size: 80,
                color: OceanThemeExtension.defaultTokens.cyan.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Fishing Spots Shared Yet',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Be the first to share a favorite fishing spot with the community!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  context.push('/spots/add');
                },
                icon: const Icon(Icons.add_location_alt),
                label: const Text('Add First Spot'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(top: 88, left: 16, right: 16, bottom: 120),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              final formattedDate = spot.createdAt != null
                  ? DateFormat.yMMMd().format(spot.createdAt!)
                  : 'Recent';

              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    context.push('/spots/${spot.id}');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                spot.name,
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
                        InkWell(
                          onTap: spot.userId.isNotEmpty
                              ? () => context.push('/profile/user/${spot.userId}')
                              : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16,
                                color: OceanThemeExtension.defaultTokens.cyan,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'By ${spot.authorName}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: OceanThemeExtension.defaultTokens.cyan,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (spot.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            spot.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (spot.species.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6.0,
                            runSpacing: 4.0,
                            children: spot.species.map((s) {
                              return Chip(
                                label: Text(
                                  s,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Floating Top Bar Overlay in List View
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: FloatingTopBar(
            leading: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: OceanThemeExtension.defaultTokens.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: OceanThemeExtension.defaultTokens.cyan,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  'Spots List',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ),
            actions: [
              FloatingTopBarButton(
                icon: Icons.map_outlined,
                tooltip: 'Back to Map View',
                onPressed: onToggleView,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
