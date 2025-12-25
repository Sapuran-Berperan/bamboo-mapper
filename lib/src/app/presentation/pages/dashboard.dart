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
    return BlocBuilder<MarkerStateBloc, MarkerState>(
      builder: (builderContext, state) {
        _markers = MarkerController(
                markerStateBloc: BlocProvider.of<MarkerStateBloc>(context))
            .fetchListMarker(state.markers, context);

        return (_sLocation == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
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
                ],
              ));
      },
    );
  }
}
