import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../map/location_providers.dart';

class TripRecorderState {
  final bool isRecording;
  final List<Map<String, double>> trailPoints;

  const TripRecorderState({
    this.isRecording = false,
    this.trailPoints = const [],
  });

  List<LatLng> get latLngPoints {
    return trailPoints
        .map((p) => LatLng(p['lat'] ?? 0.0, p['lng'] ?? 0.0))
        .toList();
  }

  TripRecorderState copyWith({
    bool? isRecording,
    List<Map<String, double>>? trailPoints,
  }) {
    return TripRecorderState(
      isRecording: isRecording ?? this.isRecording,
      trailPoints: trailPoints ?? this.trailPoints,
    );
  }
}

class TripRecorderNotifier extends Notifier<TripRecorderState> {
  @override
  TripRecorderState build() {
    ref.listen<AsyncValue<Position>>(userPositionStreamProvider, (prev, next) {
      final pos = next.asData?.value;
      if (pos != null && state.isRecording) {
        addPoint(pos.latitude, pos.longitude);
      }
    });

    return const TripRecorderState();
  }

  void startRecording() {
    state = const TripRecorderState(
      isRecording: true,
      trailPoints: [],
    );

    // Try to get initial location immediately
    final locationService = ref.read(locationServiceProvider);
    locationService.getCurrentPosition().then((pos) {
      if (state.isRecording) {
        addPoint(pos.latitude, pos.longitude);
      }
    }).catchError((_) {});
  }

  void addPoint(double lat, double lng) {
    final currentTrail = List<Map<String, double>>.from(state.trailPoints);
    if (currentTrail.isNotEmpty) {
      final last = currentTrail.last;
      final dist = Geolocator.distanceBetween(
        last['lat'] ?? 0.0,
        last['lng'] ?? 0.0,
        lat,
        lng,
      );
      // Skip if position hasn't moved at least 2 meters
      if (dist < 2.0) return;
    }

    currentTrail.add({'lat': lat, 'lng': lng});
    state = state.copyWith(trailPoints: currentTrail);
  }

  List<Map<String, double>> stopRecording() {
    final recordedPoints = List<Map<String, double>>.from(state.trailPoints);
    state = const TripRecorderState(
      isRecording: false,
      trailPoints: [],
    );
    return recordedPoints;
  }

  void reset() {
    state = const TripRecorderState();
  }
}

final tripRecorderProvider =
    NotifierProvider<TripRecorderNotifier, TripRecorderState>(
  TripRecorderNotifier.new,
);
