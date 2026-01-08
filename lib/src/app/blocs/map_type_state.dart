import 'package:flutter_bloc/flutter_bloc.dart';

enum MapType {
  openStreetMap,
  satellite,
  terrain,
  dark,
}

class MapTypeInfo {
  final String name;
  final String urlTemplate;
  final String? apiKey;

  const MapTypeInfo({
    required this.name,
    required this.urlTemplate,
    this.apiKey,
  });
}

// Map type configurations
const Map<MapType, MapTypeInfo> mapTypeConfigs = {
  MapType.openStreetMap: MapTypeInfo(
    name: 'OpenStreetMap',
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  ),
  MapType.satellite: MapTypeInfo(
    name: 'Satelit',
    urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
  ),
  MapType.terrain: MapTypeInfo(
    name: 'Terrain',
    urlTemplate: 'https://tile.opentopomap.org/{z}/{x}/{y}.png',
  ),
  MapType.dark: MapTypeInfo(
    name: 'Dark Mode',
    urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
  ),
};

// Events
abstract class MapTypeEvent {}

class ChangeMapType extends MapTypeEvent {
  final MapType mapType;
  ChangeMapType(this.mapType);
}

// State
class MapTypeState {
  final MapType currentType;
  final MapTypeInfo currentInfo;

  MapTypeState({
    this.currentType = MapType.openStreetMap,
  }) : currentInfo = mapTypeConfigs[currentType]!;

  MapTypeState copyWith({MapType? currentType}) {
    return MapTypeState(
      currentType: currentType ?? this.currentType,
    );
  }
}

// BLoC
class MapTypeBloc extends Bloc<MapTypeEvent, MapTypeState> {
  MapTypeBloc() : super(MapTypeState()) {
    on<ChangeMapType>((event, emit) {
      emit(state.copyWith(currentType: event.mapType));
    });
  }
}
