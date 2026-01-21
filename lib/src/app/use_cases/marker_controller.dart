import 'package:bamboo_app/src/app/blocs/marker_state.dart';
import 'package:bamboo_app/src/app/presentation/widgets/organism/marker_view_bottom_sheet.dart';
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
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (BuildContext modalContext) {
                return BlocProvider.value(
                  value: markerStateBloc,
                  child: MarkerViewBottomSheet(
                    parentContext: context,
                    markerId: data.id,
                    markerName: data.name,
                    markerStateBloc: markerStateBloc,
                  ),
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
