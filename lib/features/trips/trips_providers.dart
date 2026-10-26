import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'trip_model.dart';
import 'trips_repository.dart';

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepository();
});

final userTripsStreamProvider = StreamProvider<List<Trip>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(tripsRepositoryProvider);
  return repository.getUserTripsStream(user.uid);
});

final sharedTripsStreamProvider = StreamProvider<List<Trip>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  if (user == null) {
    return Stream.value([]);
  }
  final repository = ref.watch(tripsRepositoryProvider);
  return repository.getSharedTripsStream(user.uid);
});

final tripDetailStreamProvider =
    StreamProvider.family<Trip?, String>((ref, tripId) {
  final repository = ref.watch(tripsRepositoryProvider);
  return repository.getTripByIdStream(tripId);
});
