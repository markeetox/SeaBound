import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/map_layer_config.dart';

class GibsDateService {
  static final Map<String, String> _dateCache = {};

  GibsDateService({http.Client? client});

  Future<String> getLatestAvailableDate({
    required String layerIdentifier,
    required String tileMatrixSet,
  }) async {
    if (_dateCache.containsKey(layerIdentifier)) {
      return _dateCache[layerIdentifier]!;
    }

    // NASA GIBS daily products (SST & Chlorophyll) are finalized at ~T-1 12:00 UTC.
    // Deterministic date computation prevents 400 Bad Request HEAD probing logs in browser console.
    final nowUtc = DateTime.now().toUtc();
    final daysBack = nowUtc.hour < 12 ? 2 : 1;
    final validDate = nowUtc.subtract(Duration(days: daysBack));
    final dateStr = DateFormat('yyyy-MM-dd').format(validDate);

    _dateCache[layerIdentifier] = dateStr;
    return dateStr;
  }

  static String formatDisplayDate(String isoDateStr) {
    try {
      final parsed = DateTime.parse(isoDateStr);
      return DateFormat('MMM d').format(parsed);
    } catch (_) {
      return isoDateStr;
    }
  }
}

final gibsDateServiceProvider = Provider<GibsDateService>((ref) {
  return GibsDateService();
});

final sstDateProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(gibsDateServiceProvider);
  return service.getLatestAvailableDate(
    layerIdentifier: MapLayerConfig.gibsSstLayerIdentifier,
    tileMatrixSet: MapLayerConfig.gibsSstTileMatrixSet,
  );
});

final chlorophyllDateProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(gibsDateServiceProvider);
  return service.getLatestAvailableDate(
    layerIdentifier: MapLayerConfig.gibsChlorophyllLayerIdentifier,
    tileMatrixSet: MapLayerConfig.gibsChlorophyllTileMatrixSet,
  );
});
