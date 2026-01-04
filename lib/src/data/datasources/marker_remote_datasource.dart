import '../../core/network/api_client.dart';
import '../models/marker/marker_list_response.dart';
import '../models/marker/marker_response.dart';

class MarkerRemoteDataSource {
  MarkerRemoteDataSource._();
  static final MarkerRemoteDataSource instance = MarkerRemoteDataSource._();

  final ApiClient _apiClient = ApiClient.instance;

  /// Fetch all markers (lightweight list for map display)
  Future<List<MarkerListResponse>> getAllMarkers() async {
    final response = await _apiClient.getList<MarkerListResponse>(
      '/markers/',
      fromJson: MarkerListResponse.fromJson,
    );

    return response.data;
  }

  /// Fetch a single marker by ID (full details)
  Future<MarkerResponse> getMarkerById(String id) async {
    final response = await _apiClient.get<MarkerResponse>(
      '/markers/$id',
      fromJson: MarkerResponse.fromJson,
    );

    if (response.data == null) {
      throw Exception('Data marker tidak ditemukan');
    }

    return response.data!;
  }

  /// Create a new marker with optional image
  Future<MarkerResponse> createMarker({
    required String name,
    required String latitude,
    required String longitude,
    String? description,
    String? strain,
    int? quantity,
    String? ownerName,
    String? ownerContact,
    String? imagePath,
  }) async {
    final fields = <String, dynamic>{
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      if (description != null && description.isNotEmpty) 'description': description,
      if (strain != null && strain.isNotEmpty) 'strain': strain,
      if (quantity != null) 'quantity': quantity,
      if (ownerName != null && ownerName.isNotEmpty) 'owner_name': ownerName,
      if (ownerContact != null && ownerContact.isNotEmpty) 'owner_contact': ownerContact,
    };

    final response = await _apiClient.postMultipart<MarkerResponse>(
      '/markers/',
      fields: fields,
      filePath: imagePath,
      fromJson: MarkerResponse.fromJson,
    );

    if (response.data == null) {
      throw Exception('Gagal membuat marker');
    }

    return response.data!;
  }

  /// Update an existing marker with optional new image
  Future<MarkerResponse> updateMarker({
    required String id,
    String? name,
    String? latitude,
    String? longitude,
    String? description,
    String? strain,
    int? quantity,
    String? ownerName,
    String? ownerContact,
    String? imagePath,
  }) async {
    final fields = <String, dynamic>{
      if (name != null) 'name': name,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (description != null) 'description': description,
      if (strain != null) 'strain': strain,
      if (quantity != null) 'quantity': quantity,
      if (ownerName != null) 'owner_name': ownerName,
      if (ownerContact != null) 'owner_contact': ownerContact,
    };

    final response = await _apiClient.putMultipart<MarkerResponse>(
      '/markers/$id',
      fields: fields,
      filePath: imagePath,
      fromJson: MarkerResponse.fromJson,
    );

    if (response.data == null) {
      throw Exception('Gagal mengupdate marker');
    }

    return response.data!;
  }

  /// Delete a marker by ID
  Future<void> deleteMarker(String id) async {
    await _apiClient.delete('/markers/$id');
  }
}
