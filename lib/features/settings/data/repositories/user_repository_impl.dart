import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_local_datasource.dart';

/// Concrete implementation of UserRepository using local SQLite database
///
/// Combines:
/// - UserLocalDataSource for SQLite operations
/// - SharedPreferences for session management (current user ID)
///
/// This pattern allows:
/// - Easy mocking for tests
/// - Future addition of remote datasource (API calls)
/// - Session management before full authentication
class UserRepositoryImpl implements UserRepository {
  final UserLocalDataSource _dataSource;
  final SharedPreferences _prefs;

  static const String _currentUserIdKey = 'current_user_id';

  UserRepositoryImpl({
    required UserLocalDataSource dataSource,
    required SharedPreferences prefs,
  })  : _dataSource = dataSource,
        _prefs = prefs;

  @override
  Future<User?> getUserById(String userId) {
    return _dataSource.getUserById(userId);
  }

  @override
  Future<User?> getUserByEmail(String email) {
    return _dataSource.getUserByEmail(email);
  }

  @override
  Future<void> saveUser(User user) async {
    // Check if user exists
    final exists = await _dataSource.userExists(user.id);

    if (exists) {
      // User exists, update instead
      await updateUser(user);
    } else {
      // New user, insert
      await _dataSource.insertUser(user);
    }
  }

  @override
  Future<void> updateUser(User user) async {
    // Ensure updatedAt is set to current time
    final updatedUser = user.copyWith(updatedAt: DateTime.now());
    await _dataSource.updateUser(updatedUser);
  }

  @override
  Future<void> deleteUser(String userId) {
    return _dataSource.softDeleteUser(userId);
  }

  @override
  Future<List<User>> getAllUsers() {
    return _dataSource.getAllActiveUsers();
  }

  @override
  Future<String?> getCurrentUserId() async {
    return _prefs.getString(_currentUserIdKey);
  }

  @override
  Future<void> setCurrentUserId(String userId) async {
    await _prefs.setString(_currentUserIdKey, userId);
  }
}
