import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/database_date_utils.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../shared/constants/database_constants.dart';
import '../../domain/models/email_verification.dart';

/// Email Verification Local Data Source
///
/// Handles database operations for email verification tokens.
/// Manages code generation, storage, retrieval, and cleanup.
class EmailVerificationLocalDataSource {
  final DatabaseHelper _databaseHelper;
  final Random _random = Random.secure();

  EmailVerificationLocalDataSource(this._databaseHelper);

  /// Creates a new 6-digit verification code for the given email
  ///
  /// Process:
  /// 1. Invalidates any existing unused codes for this email
  /// 2. Generates a secure random 6-digit code (100000-999999)
  /// 3. Creates verification record with 15-minute expiration
  /// 4. Returns the generated code
  ///
  /// Example:
  /// ```dart
  /// final code = await dataSource.createVerificationCode('user@example.com');
  /// // code = '123456'
  /// ```
  Future<String> createVerificationCode(String email) async {
    final db = await _databaseHelper.database;

    // Invalidate existing unused codes for this email
    await db.update(
      TABLE_EMAIL_VERIFICATION_TOKENS,
      {EMAIL_VERIFICATION_IS_USED: 1},
      where: '$EMAIL_VERIFICATION_EMAIL = ? AND $EMAIL_VERIFICATION_IS_USED = 0',
      whereArgs: [email],
    );

    // Generate 6-digit code
    final code = _generateSixDigitCode();

    // Create verification record
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(minutes: 15));

    final verification = EmailVerification(
      id: UuidGenerator.generate(),
      email: email,
      code: code,
      createdAt: now,
      expiresAt: expiresAt,
      verifiedAt: null,
      isUsed: false,
    );

    await db.insert(
      TABLE_EMAIL_VERIFICATION_TOKENS,
      verification.toDatabase(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    return code;
  }

  /// Retrieves the active (unused, non-expired) verification for an email
  ///
  /// Returns null if no active verification exists.
  ///
  /// Example:
  /// ```dart
  /// final verification = await dataSource.getActiveVerification('user@example.com');
  /// if (verification != null && !verification.isExpired()) {
  ///   // Show countdown timer
  /// }
  /// ```
  Future<EmailVerification?> getActiveVerification(String email) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();

    final results = await db.query(
      TABLE_EMAIL_VERIFICATION_TOKENS,
      where: '''
        $EMAIL_VERIFICATION_EMAIL = ?
        AND $EMAIL_VERIFICATION_IS_USED = 0
        AND $EMAIL_VERIFICATION_EXPIRES_AT > ?
      ''',
      whereArgs: [email, DatabaseDateUtils.toTimestamp(now)],
      orderBy: '$EMAIL_VERIFICATION_CREATED_AT DESC',
      limit: 1,
    );

    if (results.isEmpty) {
      return null;
    }

    return EmailVerification.fromDatabase(results.first);
  }

  /// Verifies a code against the active verification for the given email
  ///
  /// Returns verification record if code matches and is valid, null otherwise.
  ///
  /// Example:
  /// ```dart
  /// final verification = await dataSource.verifyCode('user@example.com', '123456');
  /// if (verification != null) {
  ///   // Code is valid
  /// }
  /// ```
  Future<EmailVerification?> verifyCode(String email, String code) async {
    final verification = await getActiveVerification(email);

    if (verification == null) {
      return null;
    }

    if (verification.code != code) {
      return null;
    }

    return verification;
  }

  /// Marks a verification code as used
  ///
  /// Sets is_used flag to true and records verified_at timestamp.
  ///
  /// Example:
  /// ```dart
  /// await dataSource.markAsUsed(verificationId);
  /// ```
  Future<void> markAsUsed(String verificationId) async {
    final db = await _databaseHelper.database;
    final now = DateTime.now();

    await db.update(
      TABLE_EMAIL_VERIFICATION_TOKENS,
      {
        EMAIL_VERIFICATION_IS_USED: 1,
        EMAIL_VERIFICATION_VERIFIED_AT: DatabaseDateUtils.toTimestamp(now),
      },
      where: '$EMAIL_VERIFICATION_ID = ?',
      whereArgs: [verificationId],
    );
  }

  /// Cleans up expired verification tokens
  ///
  /// Deletes tokens that expired more than 24 hours ago.
  /// Should be called periodically (e.g., on app startup).
  ///
  /// Example:
  /// ```dart
  /// await dataSource.cleanupExpiredTokens();
  /// ```
  Future<void> cleanupExpiredTokens() async {
    final db = await _databaseHelper.database;
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));

    await db.delete(
      TABLE_EMAIL_VERIFICATION_TOKENS,
      where: '$EMAIL_VERIFICATION_EXPIRES_AT < ?',
      whereArgs: [DatabaseDateUtils.toTimestamp(cutoffTime)],
    );
  }

  // Private helper methods

  /// Generates a cryptographically secure 6-digit code
  ///
  /// Returns a string from '100000' to '999999'
  String _generateSixDigitCode() {
    // Generate number between 100000 and 999999
    final code = 100000 + _random.nextInt(900000);
    return code.toString();
  }
}
