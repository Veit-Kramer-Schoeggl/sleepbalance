import 'package:sqflite/sqflite.dart';
import '../../../../core/utils/database_date_utils.dart';
import '../../../../shared/constants/database_constants.dart';
import '../../domain/models/user.dart';

/// Local data source for User using SQLite
///
/// Handles all SQLite CRUD operations for users table.
/// Separates raw database operations from business logic.
class UserLocalDataSource {
  final Database database;

  UserLocalDataSource({required this.database});

  /// Get user by ID
  ///
  /// Returns the user with specified ID, or null if not found.
  /// Only returns non-deleted users.
  Future<User?> getUserById(String userId) async {
    final results = await database.query(
      TABLE_USERS,
      where: '$USERS_ID = ? AND $USERS_IS_DELETED = 0',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    return User.fromDatabase(results.first);
  }

  /// Get user by email
  ///
  /// Returns the user with specified email, or null if not found.
  /// Only returns non-deleted users.
  /// Email lookups are case-sensitive.
  Future<User?> getUserByEmail(String email) async {
    final results = await database.query(
      TABLE_USERS,
      where: '$USERS_EMAIL = ? AND $USERS_IS_DELETED = 0',
      whereArgs: [email],
      limit: 1,
    );

    if (results.isEmpty) return null;

    return User.fromDatabase(results.first);
  }

  /// Insert user
  ///
  /// Adds a new user to the database.
  /// Uses REPLACE conflict algorithm to handle ID conflicts.
  Future<void> insertUser(User user) async {
    await database.insert(
      TABLE_USERS,
      user.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update user
  ///
  /// Updates an existing user's information.
  /// Automatically sets updatedAt timestamp to current time.
  Future<void> updateUser(User user) async {
    // Ensure updatedAt is set to current time
    final updatedUser = user.copyWith(updatedAt: DateTime.now());

    await database.update(
      TABLE_USERS,
      updatedUser.toDatabase(),
      where: '$USERS_ID = ?',
      whereArgs: [user.id],
    );
  }

  /// Soft delete user
  ///
  /// Marks user as deleted without removing from database.
  /// Sets is_deleted flag to 1 and updates updatedAt timestamp.
  Future<void> softDeleteUser(String userId) async {
    await database.update(
      TABLE_USERS,
      {
        USERS_IS_DELETED: 1,
        USERS_UPDATED_AT: DatabaseDateUtils.toTimestamp(DateTime.now()),
      },
      where: '$USERS_ID = ?',
      whereArgs: [userId],
    );
  }

  /// Get all active users
  ///
  /// Returns all non-deleted users.
  /// Orders by creation date (newest first).
  Future<List<User>> getAllActiveUsers() async {
    final results = await database.query(
      TABLE_USERS,
      where: '$USERS_IS_DELETED = 0',
      orderBy: '$USERS_CREATED_AT DESC',
    );

    return results.map((map) => User.fromDatabase(map)).toList();
  }

  /// Check if user exists
  ///
  /// Returns true if a non-deleted user with the given ID exists.
  Future<bool> userExists(String userId) async {
    final result = await database.rawQuery(
      'SELECT COUNT(*) as count FROM $TABLE_USERS '
      'WHERE $USERS_ID = ? AND $USERS_IS_DELETED = 0',
      [userId],
    );

    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }
}
