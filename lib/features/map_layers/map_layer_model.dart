import 'package:flutter/material.dart';

class MapLayerItem {
  final String id;
  final String displayName;
  final IconData icon;
  final bool defaultOn;
  final String group; // 'Ocean', 'Weather', 'Tides', 'Fish'
  final void Function(BuildContext context)? onConfigure;
  final String? currentConfigLabel;

  const MapLayerItem({
    required this.id,
    required this.displayName,
    required this.icon,
    required this.defaultOn,
    required this.group,
    this.onConfigure,
    this.currentConfigLabel,
  });
}
