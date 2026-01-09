import 'package:drift/drift.dart';

import '../../core/database/database.dart';
import '../../domain/entities/e_user.dart';

/// Local data source for user operations using SQLite
class UserLocalDataSource {
  UserLocalDataSource._();
  static final UserLocalDataSource instance = UserLocalDataSource._();

  final AppDatabase _db = AppDatabase();

  // ============ Read Operations ============

  /// Get user by ID from local database
  Future<EntitiesUser?> getUserById(String id) async {
    final user = await _db.getUserById(id);
    return user != null ? _mapToEntity(user) : null;
  }

  // ============ Write Operations ============

  /// Cache user data locally (after login)
  Future<void> cacheUser(EntitiesUser user) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final companion = LocalUsersCompanion(
      id: Value(user.id),
      email: Value(user.email),
      name: Value(user.name),
      role: Value(user.role),
      createdAt: Value(user.createdAt?.millisecondsSinceEpoch),
      updatedAt: Value(user.updatedAt?.millisecondsSinceEpoch),
      cachedAt: Value(now),
    );

    await _db.upsertUser(companion);
  }

  /// Update cached user data
  Future<void> updateCachedUser(EntitiesUser user) async {
    await cacheUser(user);
  }

  /// Clear cached user data (on logout)
  Future<void> clearCachedUser() async {
    await _db.deleteAllUsers();
  }

  /// Clear all local data (for logout)
  Future<void> clearAllData() async {
    await _db.clearAllData();
  }

  // ============ Private Helper Methods ============

  /// Map database row to entity
  EntitiesUser _mapToEntity(LocalUser user) {
    return EntitiesUser(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role ?? 'user',
      createdAt: user.createdAt != null
          ? DateTime.fromMillisecondsSinceEpoch(user.createdAt!)
          : null,
      updatedAt: user.updatedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(user.updatedAt!)
          : null,
    );
  }
}
