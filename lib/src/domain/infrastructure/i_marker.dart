import 'dart:io';

import 'package:bamboo_app/src/domain/entities/e_marker.dart';
import 'package:bamboo_app/src/domain/repositories/r_marker.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class InfrastructureMarker implements RepositoryPolygon {
  final Uuid _uuid = const Uuid();
  final db = Supabase.instance.client;

  /// Extracts a unique filename from a file path using the path package.
  /// Adds timestamp prefix to ensure uniqueness.
  String _extractUniqueFilename(String filePath) {
    if (filePath.isEmpty) return '';
    final filename = p.basename(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$timestamp/$filename';
  }

  @override
  Future<EntitiesMarker?> createMarker(EntitiesMarker marker) async {
    String publicURL = '';
    String shortImageURL = _extractUniqueFilename(marker.urlImage);

    try {
      if (marker.urlImage.isNotEmpty && shortImageURL.isNotEmpty) {
        final imageRes = await createImageMarker(marker.urlImage, shortImageURL);
        if (!imageRes) {
          print('Error: Image not uploaded');
        }
        publicURL =
            db.storage.from('bamboo_images').getPublicUrl(shortImageURL);
      }
      final res = await db
          .from('marker')
          .insert(marker
              .copyWith(
                uid: _uuid.v4(),
                urlImage: publicURL,
              )
              .toJSON())
          .select()
          .single();
      return EntitiesMarker.fromJSON(res);
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  @override
  Future<EntitiesMarker?> readMarker(String uid) async {
    try {
      final res = await db.from('marker').select().eq('uid', uid).single();
      return EntitiesMarker.fromJSON(res);
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  @override
  Future<List<EntitiesMarker?>> readListMarker(String uidUser) async {
    try {
      final res =
          await db.from('marker').select().contains('uidUser', [uidUser]);
      return res.map((e) => EntitiesMarker.fromJSON(e)).toList();
    } catch (e) {
      print('Error: $e');
      return [null];
    }
  }

  @override
  Future<EntitiesMarker?> updateMarker(EntitiesMarker marker, {bool keepExistingImage = false}) async {
    String publicURL = '';
    final oldMarker = await readMarker(marker.uid);
    String shortImageURL = _extractUniqueFilename(marker.urlImage);

    try {
      if (keepExistingImage) {
        // Keep the existing image URL from the old marker
        publicURL = oldMarker?.urlImage ?? '';
      } else if (marker.urlImage.isNotEmpty && shortImageURL.isNotEmpty) {
        // Upload new image and delete old one
        final imageRes =
            await updateImageMarker(marker.urlImage, shortImageURL, oldMarker?.urlImage ?? '');
        if (!imageRes) {
          print('Error: Image not updated');
        }
        publicURL =
            db.storage.from('bamboo_images').getPublicUrl(shortImageURL);
      }

      final res = await db
          .from('marker')
          .update(marker
              .copyWith(
                urlImage: publicURL,
              )
              .toJSON())
          .eq('uid', marker.uid)
          .select()
          .single();
      return EntitiesMarker.fromJSON(res);
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  @override
  Future<void> deleteMarker(EntitiesMarker marker) async {
    try {
      if (marker.urlImage.isNotEmpty) {
        await deteleImageMarker(marker.urlImage);
      }
      await db.from('marker').delete().eq('uid', marker.uid);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Future<bool> createImageMarker(String localPath, String storagePath) async {
    final File imageFile = File(localPath);

    if (!await imageFile.exists()) {
      print('Error: Image file does not exist at $localPath');
      return false;
    }

    print('Uploading image from: $localPath');
    print('Storage path: $storagePath');

    try {
      await db.storage.from('bamboo_images').upload(storagePath, imageFile);
      return true;
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    }
  }

  @override
  Future<bool> updateImageMarker(String localPath, String storagePath, String oldImageUrl) async {
    final File imageFile = File(localPath);

    if (!await imageFile.exists()) {
      print('Error: Image file does not exist at $localPath');
      return false;
    }

    // Delete old image if exists
    if (oldImageUrl.isNotEmpty && oldImageUrl.contains('bamboo_images/')) {
      try {
        final String relativePath = oldImageUrl.split('bamboo_images/').last;
        await db.storage.from('bamboo_images').remove([relativePath]);
      } catch (e) {
        print('Error deleting old image: $e');
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
      print('Error uploading image: $e');
      return false;
    }
  }

  @override
  Future<void> deteleImageMarker(String url) async {
    final String relativePath = url.split('bamboo_images/').last;

    try {
      await db.storage.from('bamboo_images').remove([relativePath]);
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Future<void> testDeleteImageMarker() async {
    try {
      final res = await db.storage.from('bamboo_images').remove([
        'https://gysbnohwkzlxhlqcfhwn.supabase.co/storage/v1/object/public/bamboo_images/1735372142085/IMG-20241228-WA0044.jpg'
      ]);
      print('Response: $res');
    } catch (e) {
      print('Error: $e');
    }
  }
}
