import '../models/user.dart';

/// User Repository Interface
///
/// Abstract interface for user data operations.
/// Separates domain logic from data layer implementation.
///
/// Implementations handle:
/// - SQLite database operations
/// - SharedPreferences for current user ID
/// - Future: Remote API sync
abstract class UserRepository {
  /// Get user by ID
  ///
  /// Returns the user with the specified ID, or null if not found.
  Future<User?> getUserById(String userId);

  /// Get user by email
  ///
  /// Returns the user with the specified email, or null if not found.
  /// Useful for future authentication implementation.
  Future<User?> getUserByEmail(String email);

  /// Save user
  ///
  /// Inserts a new user or updates existing one based on ID.
  /// Uses upsert logic: insert if new, update if exists.
  Future<void> saveUser(User user);

  /// Update user
  ///
  /// Updates an existing user's information.
  /// Automatically sets updatedAt timestamp.
  Future<void> updateUser(User user);

  /// Delete user (soft delete)
  ///
  /// Marks user as deleted without removing from database.
  /// Soft delete allows for data recovery and historical tracking.
  Future<void> deleteUser(String userId);

  /// Get all active users
  ///
  /// Returns all non-deleted users.
  /// Ordered by creation date (newest first).
  /// Prepares for future multi-user support.
  Future<List<User>> getAllUsers();

  /// Get current user ID
  ///
  /// Returns the ID of the currently logged-in user from SharedPreferences.
  /// Returns null if no user is logged in.
  Future<String?> getCurrentUserId();

  /// Set current user ID
  ///
  /// Stores the ID of the currently logged-in user in SharedPreferences.
  /// Used for session management before full authentication is implemented.
  Future<void> setCurrentUserId(String userId);
}
