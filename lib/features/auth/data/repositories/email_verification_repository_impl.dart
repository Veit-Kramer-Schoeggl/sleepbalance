import '../../domain/models/email_verification.dart';
import '../../domain/repositories/email_verification_repository.dart';
import '../datasources/email_verification_local_datasource.dart';

/// Email Verification Repository Implementation
///
/// Implements the EmailVerificationRepository interface using local database storage.
/// Delegates to EmailVerificationLocalDataSource for database operations.
class EmailVerificationRepositoryImpl implements EmailVerificationRepository {
  final EmailVerificationLocalDataSource _dataSource;

  EmailVerificationRepositoryImpl(this._dataSource);

  @override
  Future<String> createVerificationCode(String email) async {
    try {
      return await _dataSource.createVerificationCode(email);
    } catch (e) {
      throw EmailVerificationException(
        'Failed to create verification code',
        e,
      );
    }
  }

  @override
  Future<bool> verifyCode(String email, String code) async {
    try {
      final verification = await _dataSource.verifyCode(email, code);

      if (verification == null) {
        return false;
      }

      // Verify code is valid (not used, not expired)
      if (!verification.isValid()) {
        return false;
      }

      // Mark as used
      await _dataSource.markAsUsed(verification.id);

      return true;
    } catch (e) {
      // Don't throw on verification failure, just return false
      return false;
    }
  }

  @override
  Future<EmailVerification?> getActiveVerification(String email) async {
    try {
      return await _dataSource.getActiveVerification(email);
    } catch (e) {
      throw EmailVerificationException(
        'Failed to get active verification',
        e,
      );
    }
  }

  @override
  Future<void> markAsUsed(String verificationId) async {
    try {
      await _dataSource.markAsUsed(verificationId);
    } catch (e) {
      throw EmailVerificationException(
        'Failed to mark verification as used',
        e,
      );
    }
  }

  @override
  Future<void> cleanupExpiredTokens() async {
    try {
      await _dataSource.cleanupExpiredTokens();
    } catch (e) {
      throw EmailVerificationException(
        'Failed to cleanup expired tokens',
        e,
      );
    }
  }
}

/// Exception thrown when email verification operations fail
class EmailVerificationException implements Exception {
  final String message;
  final dynamic originalError;

  EmailVerificationException(this.message, [this.originalError]);

  @override
  String toString() => 'EmailVerificationException: $message';
}
