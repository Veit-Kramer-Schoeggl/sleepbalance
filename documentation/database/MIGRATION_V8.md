# Migration V8: Email Verification Support

**Version:** 8
**Status:** ✅ Active (Current Version)
**Purpose:** Adds email verification system for secure user registration

## Overview

Migration V8 implements local-first email verification with 6-digit codes, enabling secure user registration without requiring a backend service. This migration marks the transition from development mode (with default user) to production-ready authentication.

**Changes:**
1. Creates `email_verification_tokens` table for storing verification codes
2. Adds `email_verified` column to `users` table
3. Implements security best practices (expiration, single-use codes)

## Schema Changes

### 1. New Table: `email_verification_tokens`

Stores 6-digit email verification codes with expiration and usage tracking.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for verification token |
| `email` | TEXT | NOT NULL | Email address being verified |
| `code` | TEXT | NOT NULL | 6-digit verification code (e.g., '123456') |
| `created_at` | TEXT | NOT NULL | When code was generated |
| `expires_at` | TEXT | NOT NULL | When code expires (15 minutes after creation) |
| `verified_at` | TEXT | | When code was successfully verified (NULL = not yet verified) |
| `is_used` | INTEGER | NOT NULL DEFAULT 0 | Boolean: code has been used |

**Indexes:**
- `idx_email_verification_email` on `(email)` - Fast lookups by email
- `idx_email_verification_expires` on `(expires_at)` - Efficient cleanup of expired tokens

**Security Features:**

1. **Time-Limited Codes:** 15-minute expiration window
   ```dart
   expires_at = created_at + 15 minutes
   ```

2. **Single-Use:** `is_used` flag prevents code reuse
   ```sql
   -- Valid code must be: not expired AND not used
   WHERE code = '123456'
     AND email = 'user@example.com'
     AND expires_at > datetime('now')
     AND is_used = 0
   ```

3. **Cleanup Strategy:** Expired tokens deleted after 24 hours
   ```sql
   DELETE FROM email_verification_tokens
   WHERE expires_at < datetime('now', '-24 hours');
   ```

**Use Cases:**

1. **Generate Verification Code:**
   ```dart
   // User signs up with email
   INSERT INTO email_verification_tokens (
     id, email, code, created_at, expires_at, is_used
   ) VALUES (
     'uuid', 'user@example.com', '123456',
     '2025-10-29 10:00:00', '2025-10-29 10:15:00', 0
   );
   ```

2. **Verify Code:**
   ```sql
   -- Check if code is valid
   SELECT id FROM email_verification_tokens
   WHERE email = 'user@example.com'
     AND code = '123456'
     AND expires_at > datetime('now')
     AND is_used = 0
   LIMIT 1;

   -- Mark as used
   UPDATE email_verification_tokens
   SET is_used = 1, verified_at = datetime('now')
   WHERE id = 'uuid';

   -- Update user as verified
   UPDATE users
   SET email_verified = 1, updated_at = datetime('now')
   WHERE email = 'user@example.com';
   ```

3. **Resend Code:**
   ```sql
   -- Invalidate old codes
   UPDATE email_verification_tokens
   SET is_used = 1
   WHERE email = 'user@example.com' AND is_used = 0;

   -- Generate new code
   INSERT INTO email_verification_tokens (...) VALUES (...);
   ```

4. **Cleanup Expired Tokens:**
   ```sql
   -- Run nightly or before generating new codes
   DELETE FROM email_verification_tokens
   WHERE expires_at < datetime('now', '-24 hours');
   ```

---

### 2. Updated Table: `users`

Adds email verification status tracking.

**New Column:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `email_verified` | INTEGER | NOT NULL DEFAULT 0 | Boolean: email has been verified |

**Migration SQL:**
```sql
ALTER TABLE users ADD COLUMN email_verified INTEGER NOT NULL DEFAULT 0;
```

**Usage:**

1. **Registration Flow:**
   ```dart
   // Step 1: Create user (unverified)
   INSERT INTO users (..., email_verified) VALUES (..., 0);

   // Step 2: Generate verification code
   INSERT INTO email_verification_tokens (...);

   // Step 3: User verifies code
   UPDATE users SET email_verified = 1 WHERE email = 'user@example.com';
   ```

2. **Login Guard:**
   ```sql
   -- Only allow login if email is verified
   SELECT * FROM users
   WHERE email = 'user@example.com'
     AND password_hash = 'hash'
     AND email_verified = 1;
   ```

3. **Resend Verification:**
   ```sql
   -- Check if user exists but unverified
   SELECT email FROM users
   WHERE email = 'user@example.com'
     AND email_verified = 0;
   ```

---

## Security Considerations

### Code Generation

**Recommendation:** Use cryptographically secure random number generator
```dart
import 'dart:math';

String generateVerificationCode() {
  final random = Random.secure();
  return (100000 + random.nextInt(900000)).toString(); // 6-digit code
}
```

### Email Delivery

**V8 Implementation:** Local-first (no email sending yet)
- Codes displayed in UI for development/testing
- Production: Integrate email service (SendGrid, AWS SES, etc.)

**Future Email Integration:**
```dart
// Send email with verification code
await emailService.send(
  to: user.email,
  subject: 'Verify your SleepBalance account',
  body: 'Your verification code is: ${code}',
);
```

### Rate Limiting

**Recommendation:** Prevent abuse with rate limits
- Max 3 code generations per email per hour
- Max 5 verification attempts per code
- Exponential backoff on failed attempts

**Implementation (Future):**
```sql
-- Track generation attempts
CREATE TABLE verification_rate_limits (
  email TEXT PRIMARY KEY,
  attempts INTEGER DEFAULT 0,
  window_start TIMESTAMP
);
```

### Token Storage

**Current:** Codes stored as plaintext (acceptable for time-limited verification codes)
**Alternative:** Hash codes before storage (more secure, but verification codes are low-value targets)

---

## Breaking Changes

### Default User Removed

**Before V8:** Default user auto-created on installation
```dart
// V4-V7 behavior
email: 'default@sleepbalance.app'
email_verified: 1  // Pre-verified
```

**V8+:** No default user
- Users must register with email + password
- Email verification required before login
- Enforces proper authentication flow

**Migration Impact:**
- Existing users (upgraded from V7) keep default user
- Fresh installs (V8+) start with empty users table
- Application must handle "no user" state and show registration screen

---

## Application Changes Required

### Registration Flow

```dart
// 1. User enters email + password
// 2. Create unverified user
await userRepository.createUser(email, passwordHash, emailVerified: false);

// 3. Generate verification code
final code = generateVerificationCode();
await emailVerificationRepository.createToken(email, code);

// 4. Display/send code
print('Verification code: $code'); // Dev: show in UI
// await emailService.send(...); // Prod: send email

// 5. User enters code
final isValid = await emailVerificationRepository.verifyCode(email, code);

// 6. Mark user as verified
if (isValid) {
  await userRepository.markEmailVerified(email);
}
```

### Login Flow

```dart
// Only allow verified users to login
final user = await userRepository.getUserByEmail(email);
if (user == null || !user.emailVerified) {
  throw Exception('Email not verified');
}
if (!passwordMatches(password, user.passwordHash)) {
  throw Exception('Invalid password');
}
// Proceed with login
```

---

## Migration Script Location

`lib/core/database/migrations/migration_v8.dart`

## Applied

This migration is applied during:
- Fresh database creation (version 8)
- Upgrade from version 7 to version 8

**Note:** Migration V8 SQL is split into multiple constants due to sqflite's single-statement execution limitation:
- `MIGRATION_V8_CREATE_TABLE` - Creates email_verification_tokens table
- `MIGRATION_V8_INDEX_EMAIL` - Index on email column
- `MIGRATION_V8_INDEX_EXPIRES` - Index on expires_at column
- `MIGRATION_V8_ALTER_USERS` - Adds email_verified column to users

Each statement is executed separately in `database_helper.dart`.

---

## Database Version History

| Version | Migration | Status | Key Changes |
|---------|-----------|--------|-------------|
| 1 | V1 | ✅ | Core schema (users, sleep_records, modules, etc.) |
| 2 | V2 | ✅ | Daily actions table |
| 3 | V3 | ✅ | Sleep tables (compatibility) |
| 4 | V4 | ✅ | Users table (compatibility) + default user |
| 5 | V5 | ✅ | Module configurations indexes |
| 6 | V6 | ⚠️ Disabled | Light module optimizations (triggers) |
| 7 | V7 | ✅ | Wearables integration tables |
| **8** | **V8** | ✅ **Current** | **Email verification + remove default user** |

---

## Notes

- **Current Production Version:** 8
- **Email Service:** Not yet integrated (codes displayed in UI for now)
- **Security:** 15-minute expiration, single-use codes
- **Cleanup:** Manual for now (future: background job to delete expired tokens)
- **Rate Limiting:** Not implemented yet (add in future migration)
- **Future V9:** May add password reset tokens table (similar structure)
- **Code Length:** 6 digits (balance between security and usability)
- **Accessibility:** Consider allowing custom code expiration for users who need more time
