import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/map_layers/map_layers_provider.dart';

void main() {
  group('Map Layer Registry & Grouping Tests', () {
    test('availableLayers contains Ocean, Weather, Tides, and Fish groups', () {
      final groups = availableLayers.map((l) => l.group).toSet();
      expect(groups, contains('Ocean'));
      expect(groups, contains('Weather'));
      expect(groups, contains('Tides'));
      expect(groups, contains('Fish'));
    });

    test('default active layers match defaultOn flag', () {
      final container = ProviderContainer();
      final defaultOnIds = availableLayers
          .where((l) => l.defaultOn)
          .map((l) => l.id)
          .toSet();

      final active = container.read(activeMapLayersProvider);
      expect(active, equals(defaultOnIds));
    });

    test('toggleLayer adds and removes layer IDs', () {
      final container = ProviderContainer();
      final notifier = container.read(activeMapLayersProvider.notifier);

      notifier.toggleLayer('depth_bathymetry');
      expect(container.read(activeMapLayersProvider).contains('depth_bathymetry'), isTrue);

      notifier.toggleLayer('depth_bathymetry');
      expect(container.read(activeMapLayersProvider).contains('depth_bathymetry'), isFalse);
    });

    test('clearAll resets active layers to empty', () {
      final container = ProviderContainer();
      final notifier = container.read(activeMapLayersProvider.notifier);
      expect(container.read(activeMapLayersProvider).isNotEmpty, isTrue);

      notifier.clearAll();
      expect(container.read(activeMapLayersProvider).isEmpty, isTrue);
    });
  });
}
