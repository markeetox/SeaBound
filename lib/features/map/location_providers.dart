import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final userPositionStreamProvider = StreamProvider<Position>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.getPositionStream();
});
