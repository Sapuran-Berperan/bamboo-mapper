import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/atom/custom_info_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:bamboo_app/src/domain/entities/e_marker.dart';

class MarkerController {
  final MarkerStateBloc markerStateBloc;

  MarkerController({required this.markerStateBloc});

  List<Marker> fetchListMarker(
      Set<EntitiesMarker> markers, BuildContext context) {
    final List<Marker> listMarker = [];
    for (var data in markers) {
      listMarker.add(
        Marker(
          point: data.location,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => showGeneralDialog(
              context: context,
              barrierDismissible: true,
              barrierLabel:
                  MaterialLocalizations.of(context).modalBarrierDismissLabel,
              barrierColor: Colors.black54,
              transitionDuration: const Duration(milliseconds: 200),
              pageBuilder:
                  (BuildContext buildContext, Animation a1, Animation a2) {
                return Align(
                  alignment: Alignment.center,
                  child: Material(
                    borderRadius: BorderRadius.circular(10),
                    child: BlocProvider.value(
                      value: markerStateBloc,
                      child: CustomInfoWindow(
                        markerId: data.id,
                        markerName: data.name,
                        markerStateBloc: markerStateBloc,
                      ),
                    ),
                  ),
                );
              },
              transitionBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            ),
            child: const Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40,
            ),
          ),
        ),
      );
    }
    return listMarker;
  }
}
