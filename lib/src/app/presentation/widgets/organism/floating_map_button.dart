import 'package:bamboo_app/src/app/presentation/widgets/atom/add_button.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/my_location_button.dart';
import 'package:bamboo_app/src/app/presentation/widgets/organism/modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FloatingMapButton extends StatelessWidget {
  const FloatingMapButton({
    super.key,
    required MapController controller,
  }) : _controller = controller;

  final MapController _controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MyLocationButton(onTap: () async {
          final position = await Geolocator.getCurrentPosition();
          _controller.move(
            LatLng(position.latitude, position.longitude),
            _controller.camera.zoom,
          );
        }),
        const Padding(padding: EdgeInsets.only(top: 15)),
        AddButton(
          onTap: () async => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext modalContext) =>
                ModalBottomSheet(parentContext: context),
          ),
        ),
      ],
    );
  }
}
