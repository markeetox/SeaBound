import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seabound/features/map_layers/weather_time_provider.dart';

void main() {
  group('WeatherTimeNotifier & State Unit Tests', () {
    test('initial state defaults to live (0 hour offset)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(weatherTimeProvider);
      expect(state.hourOffset, equals(0));
      expect(state.isLive, isTrue);
      expect(state.isAnimating, isFalse);
    });

    test('setHourOffset updates state to valid offset', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(weatherTimeProvider.notifier);
      notifier.setHourOffset(3);

      final state = container.read(weatherTimeProvider);
      expect(state.hourOffset, equals(3));
      expect(state.isLive, isFalse);
    });

    test('ignores invalid hour offset values', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(weatherTimeProvider.notifier);
      notifier.setHourOffset(7); // Not in availableOffsets list

      final state = container.read(weatherTimeProvider);
      expect(state.hourOffset, equals(0));
    });

    test('stepForward cycles through available offset intervals', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(weatherTimeProvider.notifier);
      notifier.setHourOffset(0);

      notifier.stepForward();
      expect(container.read(weatherTimeProvider).hourOffset, equals(1));

      notifier.stepForward();
      expect(container.read(weatherTimeProvider).hourOffset, equals(3));
    });

    test('resetToLive clears offset and restores live state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(weatherTimeProvider.notifier);
      notifier.setHourOffset(12);
      expect(container.read(weatherTimeProvider).hourOffset, equals(12));

      notifier.resetToLive();
      final resetState = container.read(weatherTimeProvider);
      expect(resetState.hourOffset, equals(0));
      expect(resetState.isLive, isTrue);
    });
  });
}
