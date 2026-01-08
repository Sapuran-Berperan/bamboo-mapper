class EntitiesUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EntitiesUser({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.createdAt,
    this.updatedAt,
  });

  EntitiesUser copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EntitiesUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory EntitiesUser.fromJSON(Map<String, dynamic> map) {
    return EntitiesUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: (map['role'] as String?) ?? 'user',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJSON() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
