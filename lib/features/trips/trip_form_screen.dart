import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import '../map/location_providers.dart';
import '../profile/badge_service.dart';
import 'trip_model.dart';
import 'trips_providers.dart';

class TripFormScreen extends ConsumerStatefulWidget {
  final String? tripId;

  const TripFormScreen({super.key, this.tripId});

  bool get isEditing => tripId != null;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  final _speciesTextController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  final List<String> _speciesList = [];

  bool _isSaving = false;
  bool _isLocating = false;
  bool _isLoaded = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
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

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLocating = true;
      _errorMessage = null;
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      final latStr = position.latitude.toStringAsFixed(4);
      final lngStr = position.longitude.toStringAsFixed(4);

      setState(() {
        _locationController.text = '$latStr, $lngStr';
      });
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveTrip(String userId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(tripsRepositoryProvider);

      if (widget.isEditing) {
        final updatedTrip = Trip(
          id: widget.tripId!,
          userId: userId,
          title: _titleController.text.trim(),
          date: _selectedDate,
          locationName: _locationController.text.trim(),
          species: List.from(_speciesList),
          notes: _notesController.text.trim(),
        );
        await repository.updateTrip(updatedTrip);
      } else {
        final newTrip = Trip(
          id: '',
          userId: userId,
          title: _titleController.text.trim(),
          date: _selectedDate,
          locationName: _locationController.text.trim(),
          species: List.from(_speciesList),
          notes: _notesController.text.trim(),
        );
        await repository.createTrip(newTrip);

        final badgeService = ref.read(badgeServiceProvider);
        final trips = await repository.getTripsOnce(userId);
        final result = await badgeService.onTripLogged(userId, trips.length);

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
          _errorMessage = 'Error saving trip: $e';
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

  void _populateTripData(Trip trip) {
    if (_isLoaded) return;
    _titleController.text = trip.title;
    _locationController.text = trip.locationName;
    _notesController.text = trip.notes;
    _selectedDate = trip.date;
    _speciesList.clear();
    _speciesList.addAll(trip.species);
    _isLoaded = true;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final user = authState.asData?.value;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: const Center(child: Text('User not authenticated.')),
      );
    }

    if (widget.isEditing) {
      final tripDetailAsync = ref.watch(tripDetailStreamProvider(widget.tripId!));

      return tripDetailAsync.when(
        data: (trip) {
          if (trip == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Edit Trip')),
              body: const Center(child: Text('Trip not found.')),
            );
          }
          _populateTripData(trip);
          return _buildFormScaffold(context, user.uid);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit Trip')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (e, st) => Scaffold(
          appBar: AppBar(title: const Text('Edit Trip')),
          body: Center(child: Text('Error loading trip: $e')),
        ),
      );
    }

    return _buildFormScaffold(context, user.uid);
  }

  Widget _buildFormScaffold(BuildContext context, String userId) {
    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Trip' : 'Log New Trip'),
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
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Trip Title *',
                      hintText: 'e.g., Morning Catch at Blue Bay',
                      border: OutlineInputBorder(),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a trip title.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat.yMMMMd().format(_selectedDate),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Select Date'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Location *',
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
                        label: const Text('Pin current location'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location Name or Coordinates *',
                      hintText: 'e.g., Cape Marina or 25.7617, -80.1918',
                      prefixIcon: Icon(Icons.place_outlined),
                      border: OutlineInputBorder(),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a location.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Species Targeted or Caught',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _speciesTextController,
                          decoration: const InputDecoration(
                            hintText: 'Add a species (e.g., Bass, Tuna)',
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
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Weather, gear used, catch details, etc.',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => _saveTrip(userId),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditing ? 'Save Changes' : 'Log Trip'),
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
