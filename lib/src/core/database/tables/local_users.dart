import 'package:drift/drift.dart';

/// Local users table - cached user profile data (NO password stored)
class LocalUsers extends Table {
  /// Primary key - User UUID
  TextColumn get id => text()();

  /// User email address
  TextColumn get email => text()();

  /// User display name
  TextColumn get name => text()();

  /// User role
  TextColumn get role => text().nullable()();

  /// Account creation timestamp (Unix milliseconds)
  IntColumn get createdAt => integer().nullable()();

  /// Last update timestamp (Unix milliseconds)
  IntColumn get updatedAt => integer().nullable()();

  /// When this record was cached locally (Unix milliseconds)
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
