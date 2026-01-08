import 'package:bamboo_app/src/app/presentation/widgets/organism/modal_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class FloatingMapButton extends StatelessWidget {
  const FloatingMapButton({
    super.key,
    required MapController controller,
    this.currentLocation,
  }) : _controller = controller;

  final MapController _controller;
  final LatLng? currentLocation;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // My Location Button (above Add button)
        FloatingActionButton(
          heroTag: 'myLocationBtn',
          backgroundColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            if (currentLocation != null) {
              _controller.move(currentLocation!, 17);
            }
          },
          child: Icon(
            Icons.my_location,
            color: Theme.of(context).textTheme.bodyMedium!.color,
          ),
        ),
        const SizedBox(height: 12),
        // Add Button (CRUD)
        FloatingActionButton(
          heroTag: 'addMarkerBtn',
          backgroundColor: Theme.of(context).colorScheme.secondary,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext modalContext) =>
                ModalBottomSheet(parentContext: context),
          ),
          child: Icon(
            Icons.add,
            color: Theme.of(context).textTheme.bodyMedium!.color,
            size: 28,
          ),
        ),
      ],
    );
  }
}
