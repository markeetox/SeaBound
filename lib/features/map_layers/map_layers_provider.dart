import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/map_layer_config.dart';
import 'map_layer_model.dart';

final availableLayers = [
  // Structure Group
  const MapLayerItem(
    id: MapLayerConfig.artificialReefsId,
    displayName: 'Artificial Reefs',
    icon: Icons.anchor,
    defaultOn: false,
    group: 'Structure',
  ),

  // Ocean Conditions Group
  const MapLayerItem(
    id: MapLayerConfig.seaTemperatureId,
    displayName: 'Sea temperature',
    icon: Icons.device_thermostat,
    defaultOn: false,
    group: 'Ocean conditions',
  ),
  const MapLayerItem(
    id: MapLayerConfig.chlorophyllId,
    displayName: 'Chlorophyll',
    icon: Icons.opacity,
    defaultOn: false,
    group: 'Ocean conditions',
  ),

  // Ocean Group
  const MapLayerItem(
    id: MapLayerConfig.depthBathymetryId,
    displayName: 'Depth Colors',
    icon: Icons.water,
    defaultOn: false,
    group: 'Ocean',
  ),
  const MapLayerItem(
    id: MapLayerConfig.depthNumbersId,
    displayName: 'Depth Numbers',
    icon: Icons.pin_drop_outlined,
    defaultOn: false,
    group: 'Ocean',
  ),
  const MapLayerItem(
    id: MapLayerConfig.wavesId,
    displayName: 'Waves',
    icon: Icons.tsunami,
    defaultOn: false,
    group: 'Ocean',
  ),

  // Weather Group
  const MapLayerItem(
    id: MapLayerConfig.weatherRadarId,
    displayName: 'Radar',
    icon: Icons.radar,
    defaultOn: false,
    group: 'Weather',
  ),
  const MapLayerItem(
    id: MapLayerConfig.windObsId,
    displayName: 'Wind & Buoys',
    icon: Icons.air,
    defaultOn: false,
    group: 'Weather',
  ),

  // Tides Group
  const MapLayerItem(
    id: MapLayerConfig.tideStationsId,
    displayName: 'Tide Stations',
    icon: Icons.waves,
    defaultOn: true,
    group: 'Tides',
  ),

  // Fish Group
  const MapLayerItem(
    id: 'fish_spots',
    displayName: 'Community Spots',
    icon: Icons.phishing,
    defaultOn: true,
    group: 'Fish',
  ),

  // Protection Group
  const MapLayerItem(
    id: MapLayerConfig.noFishingZonesId,
    displayName: 'No-Fishing Zones',
    icon: Icons.do_not_disturb_on_rounded,
    defaultOn: false,
    group: 'Protection',
  ),
];

class ActiveMapLayersNotifier extends Notifier<Set<String>> {
  static const String _prefKey = 'active_map_layers';

  @override
  Set<String> build() {
    _loadFromPrefs();
    return availableLayers
        .where((layer) => layer.defaultOn)
        .map((layer) => layer.id)
        .toSet();
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefKey);
      if (saved != null) {
        state = saved.toSet();
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKey, state.toList());
    } catch (_) {}
  }

  void toggleLayer(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state, id};
    }
    _saveToPrefs();
  }

  void setLayers(Set<String> layers) {
    state = layers;
    _saveToPrefs();
  }

  void clearAll() {
    state = {};
    _saveToPrefs();
  }

  bool isEnabled(String id) => state.contains(id);
}

final activeMapLayersProvider =
    NotifierProvider<ActiveMapLayersNotifier, Set<String>>(() {
  return ActiveMapLayersNotifier();
});
