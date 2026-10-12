import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import '../map/location_providers.dart';
import '../profile/badge_service.dart';
import '../profile/profile_providers.dart';
import 'spot_model.dart';
import 'spots_providers.dart';

class SpotFormScreen extends ConsumerStatefulWidget {
  final String? spotId;

  const SpotFormScreen({super.key, this.spotId});

  bool get isEditing => spotId != null;

  @override
  ConsumerState<SpotFormScreen> createState() => _SpotFormScreenState();
}

class _SpotFormScreenState extends ConsumerState<SpotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _speciesTextController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng? _pinnedLocation;
  final List<String> _speciesList = [];

  bool _isSaving = false;
  bool _isLocating = false;
  bool _isLoaded = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _speciesTextController.dispose();
    super.dispose();
  }

  void _addSpecies() {
    final text = _speciesTextController.text.trim();
    if (text.isNotEmpty && !_speciesList.contains(text)) {
      setState(() {
        _speciesList.add(text);
        _speciesTextController.clear();
      });
    }
  }

  void _removeSpecies(String species) {
    setState(() {
      _speciesList.remove(species);
    });
  }

  void _populateSpotData(Spot spot) {
    if (_isLoaded) return;
    _nameController.text = spot.name;
    _descriptionController.text = spot.description;
    _pinnedLocation = LatLng(spot.latitude, spot.longitude);
    _speciesList.clear();
    _speciesList.addAll(spot.species);
    _isLoaded = true;
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _pinnedLocation = userLatLng;
      });

      _mapController.move(userLatLng, 13.0);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _saveSpot(String userId, String? userDisplayName) async {
    if (!_formKey.currentState!.validate()) return;

    if (_pinnedLocation == null) {
      setState(() {
        _errorMessage = 'Please tap on the map or use your location to set a pin.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(spotsRepositoryProvider);

      if (widget.isEditing) {
        final existingSpotAsync = ref.read(spotDetailStreamProvider(widget.spotId!));
        final existingSpot = existingSpotAsync.asData?.value;

        final updatedSpot = Spot(
          id: widget.spotId!,
          userId: userId,
          authorName: existingSpot?.authorName ?? userDisplayName ?? 'Captain',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          latitude: _pinnedLocation!.latitude,
          longitude: _pinnedLocation!.longitude,
          species: List.from(_speciesList),
        );

        await repository.updateSpot(updatedSpot);
      } else {
        final authorName = (userDisplayName != null && userDisplayName.isNotEmpty)
            ? userDisplayName
            : 'Captain';

        final newSpot = Spot(
          id: '',
          userId: userId,
          authorName: authorName,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          latitude: _pinnedLocation!.latitude,
          longitude: _pinnedLocation!.longitude,
          species: List.from(_speciesList),
        );

        await repository.createSpot(newSpot);

        final badgeService = ref.read(badgeServiceProvider);
        final spots = await repository.getAllSpotsOnce();
        final userSpotsCount = spots.where((s) => s.userId == userId).length;
        final result = await badgeService.onSpotShared(userId, userSpotsCount);

        if (mounted) {
          showBadgeUnlocks(context, result);
        }
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error saving spot: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userProfile = ref.watch(userProfileProvider).asData?.value;
    final user = authState.asData?.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spot')),
        body: const Center(child: Text('User not authenticated.')),
      );
    }

    final displayName = userProfile?['displayName'] as String? ?? user.displayName;

    if (widget.isEditing) {
      final spotDetailAsync = ref.watch(spotDetailStreamProvider(widget.spotId!));

      return spotDetailAsync.when(
        data: (spot) {
          if (spot == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Spot')),
              body: const Center(child: Text('Spot not found.')),
            );
          }
          _populateSpotData(spot);
          return _buildFormScaffold(context, user.uid, displayName);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Spot')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Scaffold(
          appBar: AppBar(title: const Text('Edit Spot')),
          body: Center(child: Text('Error loading spot: $e')),
        ),
      );
    }

    return _buildFormScaffold(context, user.uid, displayName);
  }

  Widget _buildFormScaffold(
      BuildContext context, String userId, String? userDisplayName) {
    final userDoc = ref.watch(userDocStreamProvider).asData?.value;
    final userBgHex = userDoc?['avatarBgColor'] as String?;
    final userBgVal = userBgHex != null && userBgHex.startsWith('#')
        ? int.tryParse(userBgHex.replaceFirst('#', '0xFF'))
        : null;
    final pointerColor = userBgVal != null ? Color(userBgVal) : Theme.of(context).colorScheme.error;

    final initialMapCenter = _pinnedLocation ?? const LatLng(25.7617, -80.1918);

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Spot' : 'Add New Spot'),
        ),
        body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Spot Name *',
                      hintText: 'e.g., Pelican Point, Secret Reef',
                      border: OutlineInputBorder(),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a spot name.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Depth, tide preference, structure, or tips',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Species Found Here',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _speciesTextController,
                          decoration: const InputDecoration(
                            hintText: 'Add a species (e.g., Tarpon, Snook)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addSpecies(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: _addSpecies,
                        icon: const Icon(Icons.add),
                        tooltip: 'Add species',
                      ),
                    ],
                  ),
                  if (_speciesList.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: _speciesList.map((species) {
                        return Chip(
                          label: Text(species),
                          onDeleted: () => _removeSpecies(species),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Location Pin *',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      OutlinedButton.icon(
                        onPressed: _isLocating ? null : _useCurrentLocation,
                        icon: _isLocating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, size: 16),
                        label: const Text('Use my current location'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  if (_pinnedLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Pinned: ${_pinnedLocation!.latitude.toStringAsFixed(4)}, ${_pinnedLocation!.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 280,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: initialMapCenter,
                          initialZoom: _pinnedLocation != null ? 12.0 : 9.0,
                          onTap: (tapPosition, point) {
                            setState(() {
                              _pinnedLocation = point;
                              _errorMessage = null;
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.onerevamp.seabound',
                          ),
                          if (_pinnedLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _pinnedLocation!,
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
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () => _saveSpot(userId, userDisplayName),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditing ? 'Save Changes' : 'Add Spot'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
