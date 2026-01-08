import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:bamboo_app/src/app/blocs/map_type_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/modal_snackbar.dart';
import 'package:bamboo_app/src/app/presentation/widgets/organism/floating_map_button.dart';
import 'package:bamboo_app/src/app/use_cases/gps_controller.dart';
import 'package:bamboo_app/src/app/use_cases/marker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:flutter_map/flutter_map.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final MapController _mapController = MapController();
  final GpsController _gpsController = GpsController();
  List<Marker> _markers = [];
  LocationData? _locationData;
  StreamSubscription<LocationData>? _locationSubscription;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    BlocProvider.of<MarkerStateBloc>(context).add(FetchMarkerData());
  }

  Future<void> _initializeLocation() async {
    // Get initial position with heading
    LocationData data = await _gpsController.getCurrentLocationData();
    setState(() => _locationData = data);

    // Start listening for real-time location updates with heading
    _locationSubscription = _gpsController.getLocationDataStream().listen(
      (newData) {
        setState(() => _locationData = newData);
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );
  }

  void _centerOnCurrentLocation() {
    if (_locationData != null && _isMapReady) {
      _mapController.move(_locationData!.position, 17);
    }
  }

  /// Builds the location marker with heading indicator (cone/arrow)
  Widget _buildLocationMarker(double heading) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Heading cone (direction indicator) - only show if heading is valid
        if (heading >= 0 && heading <= 360)
          Transform.rotate(
            angle: heading * (math.pi / 180), // Convert degrees to radians
            child: CustomPaint(
              size: const Size(60, 60),
              painter: _HeadingConePainter(),
            ),
          ),
        // Inner circle (precise location dot)
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MapTypeBloc, MapTypeState>(
      builder: (context, mapTypeState) {
        return BlocConsumer<MarkerStateBloc, MarkerState>(
          listener: (context, state) {
            if (state.hasError && state.errorMessage != null) {
              ModalSnackbar(context).showError(state.errorMessage!);
            }
          },
          builder: (builderContext, state) {
            _markers = MarkerController(
                    markerStateBloc: BlocProvider.of<MarkerStateBloc>(context))
                .fetchListMarker(state.markers, context);

            final isInitialLoading = _locationData == null || state.isLoading;

            if (isInitialLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _locationData == null
                          ? 'Mendapatkan lokasi...'
                          : 'Memuat data...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              );
            }

            return Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _locationData!.position,
                    initialZoom: 17,
                    onMapReady: () {
                      setState(() => _isMapReady = true);
                      // Center on current location when map is ready
                      _centerOnCurrentLocation();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapTypeState.currentInfo.urlTemplate,
                      userAgentPackageName: 'com.example.bamboo_app',
                      subdomains: mapTypeState.currentType == MapType.dark
                          ? const ['a', 'b', 'c', 'd']
                          : const [],
                    ),
                    // Circle layer for current location (accuracy indicator)
                    CircleLayer(
                      circles: [
                        // Outer circle (accuracy indicator)
                        CircleMarker(
                          point: _locationData!.position,
                          radius: 40,
                          color: Colors.blue.withValues(alpha: 0.15),
                          borderColor: Colors.blue.withValues(alpha: 0.3),
                          borderStrokeWidth: 1,
                        ),
                      ],
                    ),
                    // Location marker with heading indicator
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _locationData!.position,
                          width: 60,
                          height: 60,
                          child: _buildLocationMarker(_locationData!.heading),
                        ),
                      ],
                    ),
                    MarkerLayer(markers: _markers),
                  ],
                ),
                // Map type indicator
                Positioned(
                  top: 40,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getMapTypeIcon(mapTypeState.currentType),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mapTypeState.currentInfo.name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                // Floating buttons (My Location + Add)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingMapButton(
                    controller: _mapController,
                    currentLocation: _locationData?.position,
                  ),
                ),
                if (state.isProcessing)
                  Positioned(
                    top: 90,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getProcessingMessage(state),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  IconData _getMapTypeIcon(MapType type) {
    switch (type) {
      case MapType.openStreetMap:
        return Icons.map;
      case MapType.satellite:
        return Icons.satellite_alt;
      case MapType.terrain:
        return Icons.terrain;
      case MapType.dark:
        return Icons.dark_mode;
    }
  }

  String _getProcessingMessage(MarkerState state) {
    if (state.isAdding) return 'Menambahkan...';
    if (state.isUpdating) return 'Mengupdate...';
    if (state.isDeleting) return 'Menghapus...';
    return 'Memproses...';
  }
}

/// Custom painter for the heading cone/arrow indicator
class _HeadingConePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw a cone/wedge shape pointing upward (north)
    // The transform.rotate in the parent widget will rotate it to match heading
    final path = ui.Path();

    // Start from center
    path.moveTo(center.dx, center.dy);

    // Draw arc from -30 degrees to +30 degrees (60 degree cone)
    // Using negative Y for "up" direction
    const coneAngle = 30 * (math.pi / 180); // 30 degrees in radians
    const startAngle = -math.pi / 2 - coneAngle; // Start at -120 degrees (pointing up-left)
    const sweepAngle = coneAngle * 2; // 60 degree sweep

    path.arcTo(
      Rect.fromCircle(center: center, radius: radius * 0.85),
      startAngle,
      sweepAngle,
      false,
    );

    // Close path back to center
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
