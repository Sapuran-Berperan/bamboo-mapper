import 'package:bamboo_app/src/domain/entities/e_marker.dart';
import 'package:bamboo_app/src/domain/service/s_marker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class MarkerEvent {}

class FetchMarkerData extends MarkerEvent {}

class AddMarkerData extends MarkerEvent {
  final EntitiesMarker marker;

  AddMarkerData({required this.marker});
}

class UpdateMarkerData extends MarkerEvent {
  final EntitiesMarker marker;
  final bool keepExistingImage;

  UpdateMarkerData({required this.marker, this.keepExistingImage = false});
}

class DeleteMarkerData extends MarkerEvent {
  final EntitiesMarker marker;

  DeleteMarkerData({required this.marker});
}

enum MarkerStatus { initial, loading, loaded, adding, updating, deleting, error }

class MarkerState {
  final Set<EntitiesMarker> markers;
  final MarkerStatus status;
  final String? errorMessage;

  MarkerState({
    required this.markers,
    this.status = MarkerStatus.initial,
    this.errorMessage,
  });

  bool get isLoading => status == MarkerStatus.loading;
  bool get isAdding => status == MarkerStatus.adding;
  bool get isUpdating => status == MarkerStatus.updating;
  bool get isDeleting => status == MarkerStatus.deleting;
  bool get isProcessing => isLoading || isAdding || isUpdating || isDeleting;
  bool get hasError => status == MarkerStatus.error;

  MarkerState copyWith({
    Set<EntitiesMarker>? markers,
    MarkerStatus? status,
    String? errorMessage,
  }) {
    return MarkerState(
      markers: markers ?? this.markers,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

class MarkerStateBloc extends Bloc<MarkerEvent, MarkerState> {
  final _service = ServiceMarker();

  MarkerStateBloc() : super(MarkerState(markers: {})) {
    on<FetchMarkerData>((event, emit) async {
      emit(state.copyWith(status: MarkerStatus.loading));
      try {
        final markers = await _service.fetchListMarker();
        emit(state.copyWith(markers: markers, status: MarkerStatus.loaded));
      } catch (e) {
        emit(state.copyWith(
          status: MarkerStatus.error,
          errorMessage: 'Gagal memuat data: ${e.toString()}',
        ));
      }
    });

    on<AddMarkerData>((event, emit) async {
      debugPrint('[MarkerBloc] Adding marker: ${event.marker.name}');
      emit(state.copyWith(status: MarkerStatus.adding));
      try {
        debugPrint('[MarkerBloc] Calling service.addMarker...');
        await _service.addMarker(event.marker);
        debugPrint('[MarkerBloc] Marker added, fetching updated list...');
        final markers = await _service.fetchListMarker();
        debugPrint('[MarkerBloc] Fetched ${markers.length} markers');
        emit(state.copyWith(markers: markers, status: MarkerStatus.loaded));
        debugPrint('[MarkerBloc] State emitted: loaded');
      } catch (e) {
        debugPrint('[MarkerBloc] Error adding marker: $e');
        emit(state.copyWith(
          status: MarkerStatus.error,
          errorMessage: 'Gagal menambah data: ${e.toString()}',
        ));
        debugPrint('[MarkerBloc] State emitted: error');
      }
    });

    on<UpdateMarkerData>((event, emit) async {
      debugPrint('[MarkerBloc] Updating marker: ${event.marker.id}');
      emit(state.copyWith(status: MarkerStatus.updating));
      try {
        debugPrint('[MarkerBloc] Calling service.updateMarker...');
        await _service.updateMarker(event.marker, keepExistingImage: event.keepExistingImage);
        debugPrint('[MarkerBloc] Marker updated, fetching updated list...');
        final markers = await _service.fetchListMarker();
        debugPrint('[MarkerBloc] Fetched ${markers.length} markers');
        emit(state.copyWith(markers: markers, status: MarkerStatus.loaded));
        debugPrint('[MarkerBloc] State emitted: loaded');
      } catch (e) {
        debugPrint('[MarkerBloc] Error updating marker: $e');
        emit(state.copyWith(
          status: MarkerStatus.error,
          errorMessage: 'Gagal mengupdate data: ${e.toString()}',
        ));
        debugPrint('[MarkerBloc] State emitted: error');
      }
    });

    on<DeleteMarkerData>((event, emit) async {
      debugPrint('[MarkerBloc] Deleting marker: ${event.marker.id}');
      emit(state.copyWith(status: MarkerStatus.deleting));
      try {
        debugPrint('[MarkerBloc] Calling service.deleteMarker...');
        await _service.deleteMarker(event.marker);
        debugPrint('[MarkerBloc] Marker deleted, fetching updated list...');
        final markers = await _service.fetchListMarker();
        debugPrint('[MarkerBloc] Fetched ${markers.length} markers');
        emit(state.copyWith(markers: markers, status: MarkerStatus.loaded));
        debugPrint('[MarkerBloc] State emitted: loaded');
      } catch (e) {
        debugPrint('[MarkerBloc] Error deleting marker: $e');
        emit(state.copyWith(
          status: MarkerStatus.error,
          errorMessage: 'Gagal menghapus data: ${e.toString()}',
        ));
        debugPrint('[MarkerBloc] State emitted: error');
      }
    });
  }
}
