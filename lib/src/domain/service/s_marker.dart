import 'package:bamboo_app/src/domain/entities/e_marker.dart';
import 'package:bamboo_app/src/domain/infrastructure/i_marker.dart';

class ServiceMarker {
  final _infrastructure = InfrastructureMarker();

  /// Fetch all markers (no user ID needed, backend uses JWT)
  Future<Set<EntitiesMarker>> fetchListMarker() async {
    final res = await _infrastructure.readListMarker();
    return res.toSet();
  }

  /// Fetch single marker with full details
  Future<EntitiesMarker> fetchMarker(String markerId) async {
    final res = await _infrastructure.readMarker(markerId);
    if (res == null) {
      throw Exception('Marker tidak ditemukan');
    }
    return res;
  }

  Future<void> addMarker(EntitiesMarker marker) async {
    await _infrastructure.createMarker(marker);
  }

  Future<void> updateMarker(EntitiesMarker marker, {bool keepExistingImage = false}) async {
    await _infrastructure.updateMarker(marker, keepExistingImage: keepExistingImage);
  }

  Future<void> deleteMarker(EntitiesMarker marker) async {
    await _infrastructure.deleteMarker(marker);
  }

  Future<void> testDeleteImageMarker() async {
    await _infrastructure.testDeleteImageMarker();
  }
}
