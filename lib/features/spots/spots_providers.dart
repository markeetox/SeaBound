import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'spot_model.dart';
import 'spots_repository.dart';

final spotsRepositoryProvider = Provider<SpotsRepository>((ref) {
  return SpotsRepository();
});

final allSpotsStreamProvider = StreamProvider<List<Spot>>((ref) {
  final repository = ref.watch(spotsRepositoryProvider);
  return repository.getAllSpotsStream();
});

final spotDetailStreamProvider =
    StreamProvider.family<Spot?, String>((ref, spotId) {
  final repository = ref.watch(spotsRepositoryProvider);
  return repository.getSpotByIdStream(spotId);
});
