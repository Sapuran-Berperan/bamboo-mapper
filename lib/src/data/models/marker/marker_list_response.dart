/// Lightweight marker response from GET /api/v1/markers/
/// Used for displaying markers on the map (without full details)
class MarkerListResponse {
  final String id;
  final String shortCode;
  final String name;
  final String latitude;
  final String longitude;

  MarkerListResponse({
    required this.id,
    required this.shortCode,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory MarkerListResponse.fromJson(Map<String, dynamic> json) {
    return MarkerListResponse(
      id: json['id'] as String,
      shortCode: json['short_code'] as String,
      name: json['name'] as String,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'short_code': shortCode,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
