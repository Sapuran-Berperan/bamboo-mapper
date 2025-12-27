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
  List<Marker> _markers = [];
  LatLng? _sLocation;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    BlocProvider.of<MarkerStateBloc>(context).add(FetchMarkerData());
  }

  Future<void> _getUserLocation() async {
    LatLng position = await GpsController().getCurrentPosition();
    setState(() => _sLocation = position);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MarkerStateBloc, MarkerState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          ModalSnackbar(context).show(state.errorMessage!);
        }
      },
      builder: (builderContext, state) {
        _markers = MarkerController(
                markerStateBloc: BlocProvider.of<MarkerStateBloc>(context))
            .fetchListMarker(state.markers, context);

        final isInitialLoading = _sLocation == null || state.isLoading;

        if (isInitialLoading) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _sLocation == null
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
                initialCenter: _sLocation!,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.bamboo_app',
                ),
                MarkerLayer(markers: _markers),
              ],
            ),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingMapButton(controller: _mapController),
            ),
            if (state.isProcessing)
              Positioned(
                top: 20,
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
  }

  String _getProcessingMessage(MarkerState state) {
    if (state.isAdding) return 'Menambahkan...';
    if (state.isUpdating) return 'Mengupdate...';
    if (state.isDeleting) return 'Menghapus...';
    return 'Memproses...';
  }
}
