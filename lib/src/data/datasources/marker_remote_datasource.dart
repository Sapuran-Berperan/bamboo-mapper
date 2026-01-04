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
}
