import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tide_service.dart';

final tideServiceProvider = Provider<TideService>((ref) {
  return TideService();
});

final tideStationsProvider = FutureProvider<List<TideStation>>((ref) async {
  final service = ref.watch(tideServiceProvider);
  return service.fetchTideStations();
});

final stationPredictionsProvider =
    FutureProvider.family<List<TidePrediction>, String>((ref, stationId) async {
  final service = ref.watch(tideServiceProvider);
  return service.fetchStationPredictions(stationId);
});
