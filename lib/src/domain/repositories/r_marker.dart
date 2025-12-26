import 'package:bamboo_app/src/domain/entities/e_marker.dart';

abstract class RepositoryPolygon {
  Future<EntitiesMarker?> createMarker(EntitiesMarker marker);
  Future<EntitiesMarker?> readMarker(String uid);
  Future<List<EntitiesMarker?>> readListMarker(String uidUser);
  Future<EntitiesMarker?> updateMarker(EntitiesMarker marker, {bool keepExistingImage = false});
  Future<void> deleteMarker(EntitiesMarker marker);

  Future<bool> createImageMarker(String localPath, String storagePath);
  Future<bool> updateImageMarker(String localPath, String storagePath, String oldImageUrl);
  Future<void> deteleImageMarker(String imageUrl);

  Future<void> testDeleteImageMarker();
}
