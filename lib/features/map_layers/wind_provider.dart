import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wind_service.dart';

final windServiceProvider = Provider<WindService>((ref) {
  return WindService();
});

final ndbcStationsProvider = FutureProvider<List<NdbcStationObs>>((ref) async {
  final service = ref.watch(windServiceProvider);
  return service.fetchNdbcStations();
});
