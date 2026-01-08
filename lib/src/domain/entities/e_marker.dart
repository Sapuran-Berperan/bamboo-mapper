import 'package:latlong2/latlong.dart';

import 'package:bamboo_app/src/data/models/marker/marker_list_response.dart';
import 'package:bamboo_app/src/data/models/marker/marker_response.dart';

class EntitiesMarker {
  final String id;
  final String shortCode;
  final String creatorId;
  final String name;
  final String description;
  final String strain;
  final int quantity;
  final String imageUrl;
  final String ownerName;
  final String ownerContact;
  final LatLng location;
  final DateTime createdAt;
  final DateTime updatedAt;

  EntitiesMarker({
    required this.id,
    required this.shortCode,
    required this.creatorId,
    required this.name,
    required this.description,
    required this.strain,
    required this.quantity,
    required this.imageUrl,
    required this.ownerName,
    required this.ownerContact,
    required this.location,
    required this.createdAt,
    required this.updatedAt,
  });

  EntitiesMarker copyWith({
    String? id,
    String? shortCode,
    String? creatorId,
    String? name,
    String? description,
    String? strain,
    int? quantity,
    String? imageUrl,
    String? ownerName,
    String? ownerContact,
    LatLng? location,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EntitiesMarker(
      id: id ?? this.id,
      shortCode: shortCode ?? this.shortCode,
      creatorId: creatorId ?? this.creatorId,
      name: name ?? this.name,
      description: description ?? this.description,
      strain: strain ?? this.strain,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      ownerName: ownerName ?? this.ownerName,
      ownerContact: ownerContact ?? this.ownerContact,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Create entity from full marker response (GET /markers/{id})
  factory EntitiesMarker.fromResponse(MarkerResponse response) {
    return EntitiesMarker(
      id: response.id,
      shortCode: response.shortCode,
      creatorId: response.creatorId,
      name: response.name,
      description: response.description ?? '',
      strain: response.strain ?? '',
      quantity: response.quantity ?? 0,
      imageUrl: response.imageUrl ?? '',
      ownerName: response.ownerName ?? '',
      ownerContact: response.ownerContact ?? '',
      location: LatLng(
        double.tryParse(response.latitude) ?? 0,
        double.tryParse(response.longitude) ?? 0,
      ),
      createdAt: response.createdAt,
      updatedAt: response.updatedAt,
    );
  }

  /// Create lightweight entity from list response (GET /markers/)
  /// This only has basic info for map display
  factory EntitiesMarker.fromListResponse(MarkerListResponse response) {
    final now = DateTime.now();
    return EntitiesMarker(
      id: response.id,
      shortCode: response.shortCode,
      creatorId: '',
      name: response.name,
      description: '',
      strain: '',
      quantity: 0,
      imageUrl: '',
      ownerName: '',
      ownerContact: '',
      location: LatLng(
        double.tryParse(response.latitude) ?? 0,
        double.tryParse(response.longitude) ?? 0,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Convert to JSON for API requests (create/update)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'strain': strain,
      'quantity': quantity,
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'owner_name': ownerName,
      'owner_contact': ownerContact,
    };
  }
}
