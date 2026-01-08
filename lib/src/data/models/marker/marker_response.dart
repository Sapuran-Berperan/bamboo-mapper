/// Full marker response from GET /api/v1/markers/{id}
class MarkerResponse {
  final String id;
  final String shortCode;
  final String creatorId;
  final String name;
  final String? description;
  final String? strain;
  final int? quantity;
  final String latitude;
  final String longitude;
  final String? imageUrl;
  final String? ownerName;
  final String? ownerContact;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarkerResponse({
    required this.id,
    required this.shortCode,
    required this.creatorId,
    required this.name,
    this.description,
    this.strain,
    this.quantity,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.ownerName,
    this.ownerContact,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarkerResponse.fromJson(Map<String, dynamic> json) {
    return MarkerResponse(
      id: json['id'] as String,
      shortCode: json['short_code'] as String,
      creatorId: json['creator_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      strain: json['strain'] as String?,
      quantity: json['quantity'] as int?,
      latitude: json['latitude'] as String,
      longitude: json['longitude'] as String,
      imageUrl: json['image_url'] as String?,
      ownerName: json['owner_name'] as String?,
      ownerContact: json['owner_contact'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'short_code': shortCode,
      'creator_id': creatorId,
      'name': name,
      'description': description,
      'strain': strain,
      'quantity': quantity,
      'latitude': latitude,
      'longitude': longitude,
      'image_url': imageUrl,
      'owner_name': ownerName,
      'owner_contact': ownerContact,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
