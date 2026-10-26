import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherTimeState {
  final int hourOffset; // 0, 1, 3, 6, 12, 24
  final bool isAnimating;
  final DateTime baseTime;

  WeatherTimeState({
    required this.hourOffset,
    this.isAnimating = false,
    DateTime? baseTime,
  }) : baseTime = baseTime ?? DateTime.now();

  bool get isLive => hourOffset == 0;

  DateTime get validTime => baseTime.add(Duration(hours: hourOffset));

  WeatherTimeState copyWith({
    int? hourOffset,
    bool? isAnimating,
    DateTime? baseTime,
  }) {
    return WeatherTimeState(
      hourOffset: hourOffset ?? this.hourOffset,
      isAnimating: isAnimating ?? this.isAnimating,
      baseTime: baseTime ?? this.baseTime,
    );
  }
}

class WeatherTimeNotifier extends Notifier<WeatherTimeState> {
  static const List<int> availableOffsets = [0, 1, 3, 6, 12, 24];

  @override
  WeatherTimeState build() {
    return WeatherTimeState(hourOffset: 0);
  }

  void setHourOffset(int offset) {
    if (!availableOffsets.contains(offset)) return;
    state = state.copyWith(hourOffset: offset, isAnimating: false);
  }

  void toggleAnimation() {
    final nextAnimating = !state.isAnimating;
    state = state.copyWith(isAnimating: nextAnimating);
  }

  void stepForward() {
    final currentIndex = availableOffsets.indexOf(state.hourOffset);
    final nextIndex = (currentIndex + 1) % availableOffsets.length;
    state = state.copyWith(hourOffset: availableOffsets[nextIndex]);
  }

  void resetToLive() {
    state = state.copyWith(
      hourOffset: 0,
      isAnimating: false,
      baseTime: DateTime.now(),
    );
  }
}

final weatherTimeProvider =
    NotifierProvider<WeatherTimeNotifier, WeatherTimeState>(() {
  return WeatherTimeNotifier();
});
