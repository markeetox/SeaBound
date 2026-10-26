import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'waves_service.dart';

final wavesServiceProvider = Provider<WavesService>((ref) {
  return WavesService();
});

class SelectedWaveHourOffsetNotifier extends Notifier<int> {
  @override
  int build() => 0; // Default to 'Now' (0 hours)

  void setHourOffset(int offset) {
    state = offset;
  }
}

final selectedWaveHourOffsetProvider =
    NotifierProvider<SelectedWaveHourOffsetNotifier, int>(
  SelectedWaveHourOffsetNotifier.new,
);
