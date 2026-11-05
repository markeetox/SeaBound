import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_theme.dart';
import '../../core/floating_top_bar.dart';
import '../../core/gradient_background.dart';
import '../auth/auth_providers.dart';
import 'postcard_model.dart';
import 'postcards_providers.dart';
import 'zone_matcher.dart';

class AdminPostcardFormScreen extends ConsumerStatefulWidget {
  final Postcard? postcard;

  const AdminPostcardFormScreen({super.key, this.postcard});

  bool get isEditing => postcard != null;

  @override
  ConsumerState<AdminPostcardFormScreen> createState() => _AdminPostcardFormScreenState();
}

class _AdminPostcardFormScreenState extends ConsumerState<AdminPostcardFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _locController;
  late TextEditingController _imageController;

  late LatLng _centerCoord;
  double _radiusMeters = 300.0;
  bool _active = true;
  bool _isSaving = false;

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final p = widget.postcard;
    _titleController = TextEditingController(text: p?.title ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    _locController = TextEditingController(text: p?.locationName ?? '');
    _imageController = TextEditingController(text: p?.imageUrl ?? '');

    _centerCoord = p != null
        ? LatLng(p.zone.lat, p.zone.lng)
        : const LatLng(25.7617, -80.1918); // Default Biscayne Bay
    _radiusMeters = p?.zone.radiusMeters ?? 300.0;
    _active = p?.active ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<OceanThemeExtension>() ??
        OceanThemeExtension.defaultTokens;

    return GradientBackground.blue(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 80.0, left: 16.0, right: 16.0, bottom: 40.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isEditing ? 'Edit Postcard' : 'Create Postcard',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _titleController,
                        label: 'Title *',
                        hint: 'e.g. Cape Florida Lighthouse',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _locController,
                        label: 'Location Name *',
                        hint: 'e.g. Key Biscayne, FL',
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Location name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _descController,
                        label: 'Description / Lore',
                        hint: 'Story or historical significance of this navigational point...',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _imageController,
                        label: 'Image URL (https)',
                        hint: 'https://example.com/postcard.jpg',
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Zone Definition (${_centerCoord.latitude.toStringAsFixed(4)}, ${_centerCoord.longitude.toStringAsFixed(4)})',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tap the map to set the zone center coordinate.',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _centerCoord,
                            initialZoom: 13.0,
                            onTap: (tapPosition, latLng) {
                              setState(() {
                                _centerCoord = latLng;
                              });
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.onerevamp.seabound',
                            ),
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _centerCoord,
                                  radius: _radiusMeters,
                                  useRadiusInMeter: true,
                                  color: tokens.cyan.withValues(alpha: 0.3),
                                  borderColor: tokens.cyan,
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _centerCoord,
                                  child: Icon(Icons.place, color: tokens.cyan, size: 32),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Zone Radius:',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          Text(
                            '${_radiusMeters.toStringAsFixed(0)} meters',
                            style: TextStyle(color: tokens.cyan, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Slider(
                        value: _radiusMeters,
                        min: 50.0,
                        max: 2000.0,
                        divisions: 39,
                        activeColor: tokens.cyan,
                        onChanged: (val) {
                          setState(() {
                            _radiusMeters = val;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Active Status', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Only active postcards can be earned by users', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        value: _active,
                        activeThumbColor: tokens.cyan,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          setState(() => _active = val);
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tokens.cyan,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _isSaving ? null : _savePostcard,
                          child: _isSaving
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                              : Text(widget.isEditing ? 'Save Changes' : 'Create Postcard', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            FloatingTopBar(
              leading: FloatingTopBarButton(
                icon: Icons.arrow_back,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white30),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.25),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }

  Future<void> _savePostcard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final user = ref.read(authStateProvider).asData?.value;
      final geohash = ZoneMatcher.encodeGeohash(_centerCoord.latitude, _centerCoord.longitude);

      final card = Postcard(
        id: widget.postcard?.id ?? '',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        locationName: _locController.text.trim(),
        imageUrl: _imageController.text.trim(),
        zone: CircleZone(
          lat: _centerCoord.latitude,
          lng: _centerCoord.longitude,
          radiusMeters: _radiusMeters,
        ),
        geohash: geohash,
        active: _active,
        createdBy: user?.uid ?? 'admin',
      );

      await ref.read(postcardsRepositoryProvider).savePostcard(card);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
