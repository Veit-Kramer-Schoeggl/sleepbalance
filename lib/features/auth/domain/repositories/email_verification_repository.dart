import '../models/email_verification.dart';

/// Email Verification Repository Interface
///
/// Defines contract for managing email verification codes during user registration.
/// Implementations handle code generation, validation, and cleanup.
abstract class EmailVerificationRepository {
  /// Creates a new 6-digit verification code for the given email
  ///
  /// - Generates a secure random 6-digit code (100000-999999)
  /// - Invalidates any existing unused codes for this email
  /// - Sets expiration to 15 minutes from creation
  /// - Returns the generated verification code
  ///
  /// Example:
  /// ```dart
  /// final code = await repository.createVerificationCode('user@example.com');
  /// // code = '123456'
  /// // Email user this code (or display in test mode)
  /// ```
  Future<String> createVerificationCode(String email);

  /// Verifies a code against the active verification for the given email
  ///
  /// Returns true if:
  /// - Code matches the stored code
  /// - Code has not expired
  /// - Code has not been used
  ///
  /// Returns false otherwise. Does not throw exceptions for invalid codes.
  ///
  /// Example:
  /// ```dart
  /// final isValid = await repository.verifyCode('user@example.com', '123456');
  /// if (isValid) {
  ///   // Mark email as verified
  /// }
  /// ```
  Future<bool> verifyCode(String email, String code);

  /// Retrieves the active (unused, non-expired) verification for an email
  ///
  /// Returns null if no active verification exists.
  /// Useful for checking expiration time or resending codes.
  ///
  /// Example:
  /// ```dart
  /// final verification = await repository.getActiveVerification('user@example.com');
  /// if (verification != null && !verification.isExpired()) {
  ///   final secondsLeft = verification.secondsUntilExpiration;
  ///   // Show countdown timer
  /// }
  /// ```
  Future<EmailVerification?> getActiveVerification(String email);

  /// Marks a verification code as used
  ///
  /// Sets `is_used` flag to true and records `verified_at` timestamp.
  /// Called after successful verification to prevent code reuse.
  ///
  /// Example:
  /// ```dart
  /// await repository.markAsUsed(verificationId);
  /// ```
  Future<void> markAsUsed(String verificationId);

  /// Cleans up expired verification tokens
  ///
  /// Deletes tokens that expired more than 24 hours ago.
  /// Should be called periodically (e.g., on app startup or daily background task).
  ///
  /// Example:
  /// ```dart
  /// await repository.cleanupExpiredTokens();
  /// ```
  Future<void> cleanupExpiredTokens();
}
