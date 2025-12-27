import 'dart:async';
import 'package:bamboo_app/src/app/blocs/map_type_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/modal_snackbar.dart';
import 'package:bamboo_app/src/app/presentation/widgets/organism/floating_map_button.dart';
import 'package:bamboo_app/src/app/use_cases/gps_controller.dart';
import 'package:bamboo_app/src/app/use_cases/marker_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final MapController _mapController = MapController();
  final GpsController _gpsController = GpsController();
  List<Marker> _markers = [];
  LatLng? _currentLocation;
  StreamSubscription<LatLng>? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    BlocProvider.of<MarkerStateBloc>(context).add(FetchMarkerData());
  }

  Future<void> _initializeLocation() async {
    // Get initial position
    LatLng position = await _gpsController.getCurrentPosition();
    setState(() => _currentLocation = position);

    // Start listening for real-time location updates
    _locationSubscription = _gpsController.getPositionStream().listen(
      (newPosition) {
        setState(() => _currentLocation = newPosition);
      },
      onError: (error) {
        print('Location stream error: $error');
      },
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

            final isInitialLoading = _currentLocation == null || state.isLoading;

            if (isInitialLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _currentLocation == null
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
                    initialCenter: _currentLocation!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapTypeState.currentInfo.urlTemplate,
                      userAgentPackageName: 'com.example.bamboo_app',
                      subdomains: mapTypeState.currentType == MapType.dark
                          ? const ['a', 'b', 'c', 'd']
                          : const [],
                    ),
                    // Circle layer for current location
                    CircleLayer(
                      circles: [
                        // Outer circle (accuracy indicator)
                        CircleMarker(
                          point: _currentLocation!,
                          radius: 40,
                          color: Colors.blue.withOpacity(0.15),
                          borderColor: Colors.blue.withOpacity(0.3),
                          borderStrokeWidth: 1,
                        ),
                        // Inner circle (precise location)
                        CircleMarker(
                          point: _currentLocation!,
                          radius: 8,
                          color: Colors.blue,
                          borderColor: Colors.white,
                          borderStrokeWidth: 3,
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
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
                // Location indicator button
                Positioned(
                  bottom: 90,
                  right: 20,
                  child: FloatingActionButton.small(
                    heroTag: 'locationBtn',
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      if (_currentLocation != null) {
                        _mapController.move(_currentLocation!, 17);
                      }
                    },
                    child: const Icon(Icons.my_location, size: 20),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingMapButton(controller: _mapController),
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
                              color: Colors.black.withOpacity(0.2),
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
