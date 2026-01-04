import 'package:bamboo_app/src/app/presentation/widgets/atom/auth_text_field.dart';
import 'package:bamboo_app/src/app/presentation/widgets/molecule/location_picker_map.dart';
import 'package:bamboo_app/src/app/use_cases/gps_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:latlong2/latlong.dart';

/// A composite widget that provides three methods for location input:
/// 1. Manual text entry (latitude/longitude fields)
/// 2. Use current GPS location button
/// 3. Pick on map with draggable marker
class LocationPicker extends StatefulWidget {
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final bool enabled;

  const LocationPicker({
    super.key,
    required this.latitudeController,
    required this.longitudeController,
    this.enabled = true,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  bool _isMapExpanded = false;
  bool _isLoadingGps = false;
  final GpsController _gpsController = GpsController();

  /// Parse current text field values to LatLng, returns null if invalid
  LatLng? _parseCurrentLocation() {
    final lat = double.tryParse(widget.latitudeController.text);
    final lng = double.tryParse(widget.longitudeController.text);
    if (lat != null && lng != null) {
      // Validate ranges
      if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
        return LatLng(lat, lng);
      }
    }
    return null;
  }

  /// Update text fields with the given location
  void _updateTextFields(LatLng location) {
    widget.latitudeController.text = location.latitude.toStringAsFixed(6);
    widget.longitudeController.text = location.longitude.toStringAsFixed(6);
  }

  /// Fetch current GPS location and update fields
  Future<void> _useCurrentLocation() async {
    if (_isLoadingGps) return;

    setState(() {
      _isLoadingGps = true;
    });

    try {
      final position = await _gpsController.getCurrentPosition();
      if (mounted) {
        _updateTextFields(position);
        // If map is expanded, it will pick up the change via didUpdateWidget
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingGps = false;
        });
      }
    }
  }

  /// Toggle map visibility
  void _toggleMap() async {
    if (!_isMapExpanded) {
      // Expanding map - if no valid coordinates, fetch GPS first
      if (_parseCurrentLocation() == null) {
        await _useCurrentLocation();
      }
    }
    setState(() {
      _isMapExpanded = !_isMapExpanded;
    });
  }

  /// Get initial position for map (from text fields or default)
  LatLng _getMapInitialPosition() {
    final parsed = _parseCurrentLocation();
    if (parsed != null) {
      return parsed;
    }
    // Default to a location in Indonesia if nothing is set
    return const LatLng(-7.7956, 110.3695);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.enabled,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: widget.enabled ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Row 1: Latitude & Longitude text fields
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: AuthTextField(
                    controller: widget.latitudeController,
                    hintText: 'Latitude',
                    label: 'Latitude',
                    type: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
                Padding(padding: EdgeInsets.only(left: 0.02.sw)),
                Flexible(
                  flex: 1,
                  child: AuthTextField(
                    controller: widget.longitudeController,
                    hintText: 'Longitude',
                    label: 'Longitude',
                    type: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 0.012.sh),

            // Row 2: Action buttons
            Row(
              children: [
                // Use Current Location button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingGps ? null : _useCurrentLocation,
                    icon: _isLoadingGps
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(
                      _isLoadingGps ? 'Mencari...' : 'Lokasi Saat Ini',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ),

                SizedBox(width: 0.02.sw),

                // Pick on Map toggle button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _toggleMap,
                    icon: Icon(
                      _isMapExpanded ? Icons.expand_less : Icons.map,
                      size: 18,
                    ),
                    label: Text(
                      _isMapExpanded ? 'Tutup Peta' : 'Pilih di Peta',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                      backgroundColor: _isMapExpanded
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                  ),
                ),
              ],
            ),

            // Row 3: Expandable map
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _isMapExpanded
                  ? Padding(
                      padding: EdgeInsets.only(top: 0.012.sh),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Geser peta untuk memilih lokasi',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                ),
                          ),
                          SizedBox(height: 8),
                          LocationPickerMap(
                            initialPosition: _getMapInitialPosition(),
                            onLocationChanged: _updateTextFields,
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
