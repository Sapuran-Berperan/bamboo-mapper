import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Holds location data including position and heading
class LocationData {
  final LatLng position;
  final double heading; // Heading in degrees (0-360, 0 = North)
  final double accuracy; // Accuracy in meters

  const LocationData({
    required this.position,
    required this.heading,
    this.accuracy = 0,
  });

  /// Returns true if heading is valid (device is moving)
  bool get hasValidHeading => heading >= 0 && heading <= 360;
}

class GpsController {
  Future<LatLng> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  /// Returns initial location data with heading
  Future<LocationData> getCurrentLocationData() async {
    final position = await Geolocator.getCurrentPosition();
    return LocationData(
      position: LatLng(position.latitude, position.longitude),
      heading: position.heading,
      accuracy: position.accuracy,
    );
  }

  /// Returns a stream of position updates for real-time location tracking
  Stream<LatLng> getPositionStream({
    int distanceFilter = 5, // minimum distance (meters) before update
  }) {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => LatLng(position.latitude, position.longitude));
  }

  /// Returns a stream of location data with heading for real-time tracking
  Stream<LocationData> getLocationDataStream({
    int distanceFilter = 5, // minimum distance (meters) before update
  }) {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter,
    );

    return Geolocator.getPositionStream(locationSettings: locationSettings)
        .map((position) => LocationData(
              position: LatLng(position.latitude, position.longitude),
              heading: position.heading,
              accuracy: position.accuracy,
            ));
  }
}
