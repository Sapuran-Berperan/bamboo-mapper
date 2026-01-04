import 'dart:io';

import 'package:bamboo_app/src/data/datasources/marker_remote_datasource.dart';
import 'package:bamboo_app/src/domain/entities/e_marker.dart';
import 'package:bamboo_app/src/domain/repositories/r_marker.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InfrastructureMarker implements RepositoryPolygon {
  final db = Supabase.instance.client;
  final _remoteDataSource = MarkerRemoteDataSource.instance;

  @override
  Future<EntitiesMarker?> createMarker(EntitiesMarker marker) async {
    // TODO: Migrate to new backend API
    // For now, this is disabled as create requires new backend integration
    throw UnimplementedError('Create marker not yet migrated to new backend');
  }

  @override
  Future<EntitiesMarker?> readMarker(String id) async {
    try {
      final response = await _remoteDataSource.getMarkerById(id);
      return EntitiesMarker.fromResponse(response);
    } catch (e) {
      debugPrint('Error reading marker: $e');
      rethrow;
    }
  }

  @override
  Future<List<EntitiesMarker>> readListMarker() async {
    try {
      final response = await _remoteDataSource.getAllMarkers();
      return response.map((e) => EntitiesMarker.fromListResponse(e)).toList();
    } catch (e) {
      debugPrint('Error reading marker list: $e');
      return [];
    }
  }

  @override
  Future<EntitiesMarker?> updateMarker(EntitiesMarker marker, {bool keepExistingImage = false}) async {
    // TODO: Migrate to new backend API
    throw UnimplementedError('Update marker not yet migrated to new backend');
  }

  @override
  Future<void> deleteMarker(EntitiesMarker marker) async {
    // TODO: Migrate to new backend API
    throw UnimplementedError('Delete marker not yet migrated to new backend');
  }

  @override
  Future<bool> createImageMarker(String localPath, String storagePath) async {
    final File imageFile = File(localPath);

    if (!await imageFile.exists()) {
      debugPrint('Error: Image file does not exist at $localPath');
      return false;
    }

    debugPrint('Uploading image from: $localPath');
    debugPrint('Storage path: $storagePath');

    try {
      await db.storage.from('bamboo_images').upload(storagePath, imageFile);
      return true;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return false;
    }
  }

  @override
  Future<bool> updateImageMarker(String localPath, String storagePath, String oldImageUrl) async {
    final File imageFile = File(localPath);

    if (!await imageFile.exists()) {
      debugPrint('Error: Image file does not exist at $localPath');
      return false;
    }

    // Delete old image if exists
    if (oldImageUrl.isNotEmpty && oldImageUrl.contains('bamboo_images/')) {
      try {
        final String relativePath = oldImageUrl.split('bamboo_images/').last;
        await db.storage.from('bamboo_images').remove([relativePath]);
      } catch (e) {
        debugPrint('Error deleting old image: $e');
        // Continue with upload even if delete fails
      }
    }

    // Upload new image
    try {
      await db.storage.from('bamboo_images').upload(
            storagePath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      return true;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return false;
    }
  }

  @override
  Future<void> deteleImageMarker(String url) async {
    final String relativePath = url.split('bamboo_images/').last;

    try {
      await db.storage.from('bamboo_images').remove([relativePath]);
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  @override
  Future<void> testDeleteImageMarker() async {
    try {
      final res = await db.storage.from('bamboo_images').remove([
        'https://gysbnohwkzlxhlqcfhwn.supabase.co/storage/v1/object/public/bamboo_images/1735372142085/IMG-20241228-WA0044.jpg'
      ]);
      debugPrint('Response: $res');
    } catch (e) {
      debugPrint('Error: $e');
    }
  }
}
