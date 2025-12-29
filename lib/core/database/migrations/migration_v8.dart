// ignore_for_file: constant_identifier_names

import '../../../shared/constants/database_constants.dart';

/// Migration V8: Email Verification Support
///
/// Adds email verification table and updates users table with email_verified flag.
/// Supports local-first email verification with 6-digit codes.
///
/// Changes:
/// 1. Creates email_verification_tokens table for storing 6-digit verification codes
/// 2. Adds email_verified column to users table
/// 3. Adds indexes for efficient lookups and cleanup
///
/// Security:
/// - Verification codes expire after 15 minutes
/// - Codes are single-use (is_used flag)
/// - Expired tokens cleaned up after 24 hours

const String MIGRATION_V8 = '''
-- ============================================================================
-- Email Verification Tokens Table
-- ============================================================================
-- Stores verification codes for email verification during signup
-- Codes expire after 15 minutes for security

CREATE TABLE IF NOT EXISTS $TABLE_EMAIL_VERIFICATION_TOKENS (
  $EMAIL_VERIFICATION_ID TEXT PRIMARY KEY,
  $EMAIL_VERIFICATION_EMAIL TEXT NOT NULL,
  $EMAIL_VERIFICATION_CODE TEXT NOT NULL,
  $EMAIL_VERIFICATION_CREATED_AT TEXT NOT NULL,
  $EMAIL_VERIFICATION_EXPIRES_AT TEXT NOT NULL,
  $EMAIL_VERIFICATION_VERIFIED_AT TEXT,
  $EMAIL_VERIFICATION_IS_USED INTEGER NOT NULL DEFAULT 0
);

-- Index for quick email lookups
CREATE INDEX IF NOT EXISTS idx_email_verification_email
  ON $TABLE_EMAIL_VERIFICATION_TOKENS($EMAIL_VERIFICATION_EMAIL);

-- Index for cleanup of expired tokens
CREATE INDEX IF NOT EXISTS idx_email_verification_expires
  ON $TABLE_EMAIL_VERIFICATION_TOKENS($EMAIL_VERIFICATION_EXPIRES_AT);

-- ============================================================================
-- Users Table Updates
-- ============================================================================
-- Add email_verified column to users table

ALTER TABLE $TABLE_USERS ADD COLUMN $USERS_EMAIL_VERIFIED INTEGER NOT NULL DEFAULT 0;
''';
