import '../../../../core/utils/uuid_generator.dart';
import '../../../settings/domain/models/user.dart';
import '../../../settings/domain/repositories/user_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/password_hash_service.dart';

/// Authentication Repository Implementation
///
/// Implements the AuthRepository interface using local database storage.
/// Handles user registration and email verification status management.
class AuthRepositoryImpl implements AuthRepository {
  final UserRepository _userRepository;

  AuthRepositoryImpl(this._userRepository);

  @override
  Future<User> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String timezone,
  }) async {
    try {
      // Check if email already exists
      final existingUser = await _userRepository.getUserByEmail(email);
      if (existingUser != null) {
        throw EmailAlreadyExistsException(email);
      }

      // Hash password using Argon2id
      final passwordHash = PasswordHashService.hashPassword(password);

      // Create user
      final now = DateTime.now();
      final user = User(
        id: _generateUserId(),
        email: email,
        passwordHash: passwordHash,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        timezone: timezone,
        emailVerified: false, // Email not verified yet
        createdAt: now,
        updatedAt: now,
      );

      // Save user to database
      await _userRepository.saveUser(user);

      // Set as current user
      await _userRepository.setCurrentUserId(user.id);

      return user;
    } on EmailAlreadyExistsException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Failed to register user: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<void> markEmailVerified(String email) async {
    try {
      final user = await _userRepository.getUserByEmail(email);

      if (user == null) {
        throw AuthException('User not found with email: $email');
      }

      // Update user with email verified flag
      final updatedUser = user.copyWith(
        emailVerified: true,
        updatedAt: DateTime.now(),
      );

      await _userRepository.updateUser(updatedUser);
    } catch (e) {
      if (e is AuthException) {
        rethrow;
      }
      throw AuthException(
        'Failed to mark email as verified: ${e.toString()}',
        e,
      );
    }
  }

  @override
  Future<bool> isEmailRegistered(String email) async {
    try {
      final user = await _userRepository.getUserByEmail(email);
      return user != null;
    } catch (e) {
      throw AuthException(
        'Failed to check if email is registered: ${e.toString()}',
        e,
      );
    }
  }

  // Private helper methods

  /// Generates a unique user ID
  ///
  /// Uses UUID v4 format for distributed ID generation.
  String _generateUserId() {
    return UuidGenerator.generate();
  }
}
