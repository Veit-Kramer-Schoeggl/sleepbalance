import '../../../settings/domain/models/user.dart';

/// Authentication Repository Interface
///
/// Defines contract for user authentication operations including registration
/// and email verification status management.
abstract class AuthRepository {
  /// Registers a new user with email and password
  ///
  /// Steps:
  /// 1. Checks if email is already registered
  /// 2. Hashes the password using Argon2id
  /// 3. Creates user record with email_verified = false
  /// 4. Sets as current user
  /// 5. Returns created User
  ///
  /// Throws [EmailAlreadyExistsException] if email is already in use.
  /// Throws [AuthException] for other errors.
  ///
  /// Example:
  /// ```dart
  /// final user = await repository.registerUser(
  ///   email: 'user@example.com',
  ///   password: 'SecurePass123',
  ///   firstName: 'John',
  ///   lastName: 'Doe',
  ///   birthDate: DateTime(1990, 1, 1),
  ///   timezone: 'America/Los_Angeles',
  /// );
  /// ```
  Future<User> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String timezone,
  });

  /// Marks a user's email as verified
  ///
  /// Updates the user record to set email_verified = true.
  /// Called after successful email verification code validation.
  ///
  /// Throws [AuthException] if user not found.
  ///
  /// Example:
  /// ```dart
  /// await repository.markEmailVerified('user@example.com');
  /// ```
  Future<void> markEmailVerified(String email);

  /// Checks if an email is already registered
  ///
  /// Returns true if a user with this email exists in the database.
  /// Used during registration to prevent duplicate accounts.
  ///
  /// Example:
  /// ```dart
  /// final exists = await repository.isEmailRegistered('user@example.com');
  /// if (exists) {
  ///   // Show error: email already in use
  /// }
  /// ```
  Future<bool> isEmailRegistered(String email);
}

/// Exception thrown when attempting to register with an email that already exists
class EmailAlreadyExistsException implements Exception {
  final String email;
  final String message;

  EmailAlreadyExistsException(this.email)
      : message = 'An account with email "$email" already exists';

  @override
  String toString() => 'EmailAlreadyExistsException: $message';
}

/// General authentication exception
class AuthException implements Exception {
  final String message;
  final dynamic originalError;

  AuthException(this.message, [this.originalError]);

  @override
  String toString() => 'AuthException: $message';
}
