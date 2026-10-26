import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../map/location_providers.dart';
import 'alerts_repository.dart';
import 'weather_alert_model.dart';

class AlertsState {
  final List<WeatherAlert> alerts;
  final DateTime? lastChecked;
  final bool isLoading;
  final String? errorMessage;
  final bool isOutOfCoverage;

  const AlertsState({
    this.alerts = const [],
    this.lastChecked,
    this.isLoading = false,
    this.errorMessage,
    this.isOutOfCoverage = false,
  });

  AlertsState copyWith({
    List<WeatherAlert>? alerts,
    DateTime? lastChecked,
    bool? isLoading,
    String? errorMessage,
    bool? isOutOfCoverage,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      lastChecked: lastChecked ?? this.lastChecked,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isOutOfCoverage: isOutOfCoverage ?? this.isOutOfCoverage,
    );
  }
}

class AlertsNotifier extends Notifier<AlertsState> {
  Timer? _periodicTimer;
  AppLifecycleListener? _lifecycleListener;
  LatLng? _lastQueryPoint;
  DateTime? _lastFetchTime;

  @override
  AlertsState build() {
    _periodicTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      refreshAlerts(force: true);
    });

    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        refreshAlerts();
      },
    );

    ref.onDispose(() {
      _periodicTimer?.cancel();
      _lifecycleListener?.dispose();
    });

    Future.microtask(() => refreshAlerts(force: true));

    return const AlertsState();
  }

  Future<void> refreshAlerts({bool force = false}) async {
    final now = DateTime.now();
    if (!force && _lastFetchTime != null && now.difference(_lastFetchTime!).inSeconds < 60) {
      return;
    }

    LatLng queryPoint = const LatLng(25.7617, -80.1918);

    try {
      final userPosAsync = ref.read(userPositionStreamProvider);
      final Position? pos = userPosAsync.asData?.value;
      if (pos != null) {
        queryPoint = LatLng(pos.latitude, pos.longitude);
      } else {
        final locationService = ref.read(locationServiceProvider);
        final permission = await locationService.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await locationService.getCurrentPosition();
          queryPoint = LatLng(position.latitude, position.longitude);
        }
      }
    } catch (_) {
      // Fallback to default query point
    }

    _lastQueryPoint = queryPoint;
    await fetchAlertsForPoint(queryPoint.latitude, queryPoint.longitude);
  }

  void onPositionUpdate(Position position) {
    final currentPoint = LatLng(position.latitude, position.longitude);
    if (_lastQueryPoint != null) {
      final distanceInMeters = const Distance().as(
        LengthUnit.Meter,
        _lastQueryPoint!,
        currentPoint,
      );
      if (distanceInMeters >= 5000) {
        refreshAlerts();
      }
    } else {
      refreshAlerts();
    }
  }

  List<WeatherAlert> _filterActiveAlerts(List<WeatherAlert> incoming) {
    final now = DateTime.now();
    return incoming.where((alert) {
      if (alert.expires == null) return true;
      return alert.expires!.isAfter(now);
    }).toList();
  }

  Future<void> fetchAlertsForPoint(double lat, double lon) async {
    state = state.copyWith(isLoading: true);
    _lastFetchTime = DateTime.now();

    final repository = ref.read(alertsRepositoryProvider);

    try {
      final fetched = await repository.fetchActiveAlerts(lat, lon);
      final activeAlerts = _filterActiveAlerts(fetched);

      final validExisting = _filterActiveAlerts(state.alerts);
      final combinedAlerts = activeAlerts.isNotEmpty
          ? activeAlerts
          : (validExisting.isNotEmpty ? validExisting : const <WeatherAlert>[]);

      state = AlertsState(
        alerts: combinedAlerts,
        lastChecked: DateTime.now(),
        isLoading: false,
        errorMessage: null,
        isOutOfCoverage: false,
      );
    } catch (e) {
      if (e is OutOfCoverageException) {
        final validExisting = _filterActiveAlerts(state.alerts);
        state = AlertsState(
          alerts: validExisting,
          lastChecked: state.lastChecked ?? DateTime.now(),
          isLoading: false,
          errorMessage: null,
          isOutOfCoverage: validExisting.isEmpty,
        );
      } else {
        final validExisting = _filterActiveAlerts(state.alerts);
        state = AlertsState(
          alerts: validExisting,
          lastChecked: state.lastChecked,
          isLoading: false,
          errorMessage: validExisting.isEmpty
              ? "Couldn't check alerts. Do not assume the area is clear."
              : null,
          isOutOfCoverage: false,
        );
      }
    }
  }
}

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository();
});

final alertsNotifierProvider =
    NotifierProvider<AlertsNotifier, AlertsState>(AlertsNotifier.new);
