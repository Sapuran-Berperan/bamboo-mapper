import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class GpsController {
  Future<LatLng> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }
}
