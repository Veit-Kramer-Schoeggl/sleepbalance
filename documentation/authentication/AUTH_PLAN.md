# Authentication System Plan

**Document Version:** 1.1
**Created:** 2025-12-29
**Last Updated:** 2025-12-29
**Status:** Phase 1 Complete | Phase 2 & 3 Pending Backend

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Analysis](#current-state-analysis)
3. [Authentication Requirements](#authentication-requirements)
4. [System Architecture](#system-architecture)
5. [Authentication Flows](#authentication-flows)
6. [Database Schema Changes](#database-schema-changes)
7. [Security Implementation](#security-implementation)
8. [Local-Remote Sync Strategy](#local-remote-sync-strategy)
9. [Multi-Device Considerations](#multi-device-considerations)
10. [Implementation Phases](#implementation-phases)
11. [Technical Stack](#technical-stack)
12. [API Endpoints](#api-endpoints)
13. [Testing Strategy](#testing-strategy)
14. [Migration Path](#migration-path)

---

## Executive Summary

**Current Status (2025-12-29):** Phase 1 Complete | Phase 2 & 3 Pending Backend

### ✅ What's Implemented (Phase 1 - Local Authentication)

- **User Registration**: Email + password signup with PBKDF2 hashing (600k iterations)
- **Email Verification**: 6-digit codes with 15-minute expiration
- **User Login**: PBKDF2 password verification with conditional navigation
- **Session Management**: Local-only via SharedPreferences (no JWT yet)
- **Logout**: Clears session + terminates app
- **Password Validation**: Real-time strength indicator with requirements checklist
- **Offline-First**: All authentication works without internet
- **Testing**: 115+ unit tests covering all auth components

### ❌ What's Pending (Phase 2 & 3 - Requires Backend)

- **JWT Token Authentication**: Access + refresh tokens (Phase 2)
- **Backend API**: Signup, login, refresh, logout endpoints (Phase 2)
- **Token Refresh**: Automatic token rotation (Phase 2)
- **Multi-Device Sync**: Data synchronization across devices (Phase 2)
- **Biometric Auth**: Fingerprint/face login (Phase 2)
- **OAuth Social Login**: Google, Apple integration (Phase 3)
- **Password Reset**: Email-based reset flow (Phase 2)
- **2FA**: Two-factor authentication (Phase 3)

### Architecture Overview

This document outlines the complete authentication roadmap for SleepBalance:

- **Phase 1 (✅ Complete)**: Local-first authentication with offline capability
- **Phase 2 (❌ Pending)**: Remote backend sync for multi-device support + JWT tokens
- **Phase 3 (❌ Pending)**: OAuth integration, biometrics, and advanced features

**Key Design Principles:**
- ✅ **Local-first**: App works offline, syncs when online (Phase 1 complete)
- 🔄 **Security**: PBKDF2 implemented (Phase 1), JWT + rate limiting pending (Phase 2)
- ❌ **Privacy**: User data encrypted at rest/transit (requires backend in Phase 2)
- 🔄 **UX**: Basic auth complete (Phase 1), biometric auth pending (Phase 2)
- ❌ **Scalability**: Designed for multi-device sync (implementation in Phase 2)

---

## Current State Analysis

### What Exists

✅ **Database Schema**
- `users` table with `password_hash` field (prepared but unused)
- `synced_at` timestamps on all tables for sync tracking
- UUID-based IDs for distributed data generation
- Soft delete pattern (`is_deleted` flag)

✅ **Architecture Patterns**
- Clean architecture (domain/data/presentation layers)
- Repository pattern fully implemented
- Provider-based state management (ViewModel + ChangeNotifier)
- Database migration system (currently at v7)

✅ **User Management**
- `UserRepository` interface and implementation
- `SettingsViewModel` for user state management
- SharedPreferences for session storage (`current_user_id`)
- User CRUD operations in `UserLocalDataSource`

✅ **Related Infrastructure**
- OAuth patterns in wearables integration (Fitbit)
- Token management patterns (`WearableCredentials`)
- Date/time utilities for timestamp handling

### What's Missing (Updated 2025-12-29)

✅ **Authentication Logic** - PHASE 1 COMPLETED
- ✅ Signup/login screens implemented
- ✅ Password hashing with PBKDF2-HMAC-SHA256 (600k iterations)
- ✅ Email verification with 6-digit codes
- ✅ Session management via SharedPreferences
- ✅ Logout functionality with app termination

❌ **Backend Infrastructure** - PHASE 2 (PENDING)
- ❌ No API server
- ❌ No authentication endpoints
- ❌ No JWT token generation/validation
- ❌ No automatic token refresh mechanism
- ❌ No backend email delivery

❌ **Advanced Security** - PHASE 2 & 3 (PENDING)
- ❌ No JWT secure token storage (flutter_secure_storage)
- ❌ No biometric authentication
- ❌ No backend rate limiting
- ❌ No 2FA

❌ **Multi-Device Support** - PHASE 2 (PENDING)
- ❌ No user switching (single user per app instance)
- ❌ No multi-device sync
- ❌ No device management
- ❌ No backend sync infrastructure

---

## Authentication Requirements

### Functional Requirements

**FR-1: User Registration** ✅ PHASE 1 COMPLETED
- ✅ Email + password signup
- ✅ Password strength validation (8+ chars, uppercase, lowercase, number)
- ✅ Email verification (6-digit codes, 15-min expiration)
- ✅ Profile creation (name, birthdate, timezone)

**FR-2: User Login** ✅ PHASE 1 COMPLETED
- ✅ Email + password authentication (PBKDF2 verification)
- ✅ Conditional navigation (first launch → questionnaire, returning → main app)
- ⏸️ Remember me functionality - DEFERRED (not needed for single-user)
- ❌ Biometric login (fingerprint/face) - PHASE 2 (requires backend)
- ❌ OAuth social login (Google, Apple) - PHASE 3 (requires backend)

**FR-3: Session Management** 🔄 PARTIAL (Local-Only Complete)
- ❌ JWT-based token authentication - PHASE 2 (requires backend)
- ❌ Automatic token refresh - PHASE 2 (requires backend)
- ✅ Logout functionality (clears SharedPreferences + terminates app)
- ❌ Session expiration handling - PHASE 2 (current sessions never expire)

**FR-4: Password Management** ❌ PHASE 2 (Requires Backend)
- ❌ Password reset flow (email-based) - requires backend email service
- ❌ Change password (when authenticated) - requires backend API
- ✅ Password strength requirements (implemented in signup)
- ❌ Password history (prevent reuse) - PHASE 3

**FR-5: Multi-Device Support** ❌ PHASE 2 (Requires Backend)
- ❌ Login from multiple devices - requires backend sync
- ❌ Data sync across devices - requires backend API
- ❌ Device management (view/revoke sessions) - requires backend tracking
- ❌ Conflict resolution for concurrent edits - requires sync logic

**FR-6: Offline Capability** ✅ PHASE 1 COMPLETED
- ✅ Local authentication when offline (fully offline-capable)
- ✅ All auth operations work without internet
- ❌ Queue sync operations - PHASE 2 (requires backend)
- ❌ Automatic sync when online - PHASE 2 (requires backend)
- ❌ Conflict detection and resolution - PHASE 2 (requires backend)

### Non-Functional Requirements

**NFR-1: Security**
- Passwords hashed with Argon2id or bcrypt (cost factor 12+)
- JWTs signed with RS256 (asymmetric keys)
- Secure token storage (Flutter Secure Storage)
- HTTPS-only communication
- Rate limiting on auth endpoints

**NFR-2: Performance**
- Login response < 2 seconds (with network)
- Offline login < 500ms
- Token refresh in background
- Minimal battery impact

**NFR-3: Privacy**
- Minimal data collection
- GDPR-compliant data handling
- User data deletion support
- Local encryption at rest

**NFR-4: Usability**
- Biometric authentication support
- Auto-fill credentials support
- Clear error messages
- Seamless migration from current state

---

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App (Client)                    │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │ Presentation  │  │   Domain      │  │     Data      │   │
│  │               │  │               │  │               │   │
│  │ - Login UI    │  │ - Auth Use    │  │ - Auth Repo   │   │
│  │ - Signup UI   │  │   Cases       │  │   Impl        │   │
│  │ - ViewModels  │  │ - User Entity │  │ - Local DS    │   │
│  │               │  │ - Token Model │  │ - Remote DS   │   │
│  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘   │
│          │                  │                  │             │
│          └──────────────────┴──────────────────┘             │
│                             │                                │
│  ┌──────────────────────────┴──────────────────────────┐   │
│  │          Local Storage (SQLite + Secure Storage)     │   │
│  │  - User credentials (hashed)                         │   │
│  │  - Session tokens (encrypted)                        │   │
│  │  - Offline auth cache                                │   │
│  └──────────────────────────────────────────────────────┘   │
│                             │                                │
└─────────────────────────────┼────────────────────────────────┘
                              │ HTTPS (TLS 1.3)
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Backend Server (Future)                   │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐   │
│  │   API Layer   │  │ Business Logic│  │   Database    │   │
│  │               │  │               │  │               │   │
│  │ - Auth Routes │  │ - User Svc    │  │ - PostgreSQL  │   │
│  │ - Token Mgmt  │  │ - Token Svc   │  │ - Users       │   │
│  │ - Rate Limit  │  │ - Sync Svc    │  │ - Sessions    │   │
│  │               │  │               │  │ - Sync Queue  │   │
│  └───────────────┘  └───────────────┘  └───────────────┘   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Component Breakdown

#### **Presentation Layer**

**Screens:**
- `LoginScreen` - Email/password login
- `SignupScreen` - User registration flow
- `ForgotPasswordScreen` - Password reset request
- `ResetPasswordScreen` - New password entry (via email link)
- `BiometricSetupScreen` - Enable biometric auth (Phase 2)

**ViewModels:**
- `AuthViewModel` - Login/signup/logout state management
- `SessionViewModel` - Token management and refresh
- `ProfileViewModel` - User profile updates (extends existing SettingsViewModel)

#### **Domain Layer**

**Models:**
- `AuthCredentials` - Email + password for login
- `AuthToken` - JWT access + refresh tokens
- `AuthSession` - Current session info (user, token, device)
- `AuthUser` - Enhanced User model with auth metadata

**Use Cases:**
- `LoginUseCase` - Handle login flow
- `SignupUseCase` - Handle registration
- `RefreshTokenUseCase` - Auto-refresh JWT
- `LogoutUseCase` - Clear session and sync
- `ValidatePasswordUseCase` - Password strength check

**Repository Interfaces:**
- `AuthRepository` - Authentication operations
- `TokenRepository` - Token storage/retrieval
- `SessionRepository` - Session management

#### **Data Layer**

**Data Sources:**

*Local:*
- `AuthLocalDataSource` - SQLite auth tables
- `SecureStorageDataSource` - Flutter Secure Storage for tokens
- `BiometricDataSource` - Local Authentication plugin (Phase 2)

*Remote:*
- `AuthRemoteDataSource` - Backend auth API calls
- `SyncRemoteDataSource` - Data synchronization API

**Repository Implementations:**
- `AuthRepositoryImpl` - Delegates to local/remote sources
- `TokenRepositoryImpl` - Manages JWT lifecycle
- `SessionRepositoryImpl` - Tracks active sessions

---

## Authentication Flows

### 1. First Launch Flow (Onboarding)

```
User opens app → Splash Screen → Check if logged in?
                                      │
                      ┌───────────────┴───────────────┐
                      │                               │
                     NO                              YES
                      │                               │
                      ▼                               ▼
              Onboarding Choice              Load user profile
                      │                               │
        ┌─────────────┴─────────────┐                │
        │                           │                 │
    "Sign Up"                  "Log In"               │
        │                           │                 │
        ▼                           ▼                 │
  SignupScreen                LoginScreen             │
        │                           │                 │
        │                           │                 │
        └───────────┬───────────────┘                 │
                    │                                 │
                    ▼                                 │
            Create Account/Login                      │
                    │                                 │
                    ▼                                 │
        Questionnaire (optional)                      │
                    │                                 │
                    └─────────────────────────────────┤
                                                      │
                                                      ▼
                                               Main App (Action Center)
```

### 2. Signup Flow

```
┌──────────────┐
│ SignupScreen │
└──────┬───────┘
       │
       │ User enters:
       │ - Email
       │ - Password (2x for confirmation)
       │ - First Name
       │ - Last Name
       │ - Birth Date
       │
       ▼
┌────────────────────────────────┐
│ Validate Input                 │
│ - Email format                 │
│ - Password strength (8+ chars) │
│ - Passwords match              │
│ - Age > 13                     │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│ Hash Password (Argon2id)       │
│ - Generate salt                │
│ - Hash with cost factor 12     │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│ Create User Locally            │
│ - Generate UUID                │
│ - Store in SQLite              │
│ - Mark as unsynced             │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│ Create Auth Session            │
│ - Generate JWT (local)         │
│ - Store in Secure Storage      │
│ - Set current_user_id          │
└────────┬───────────────────────┘
         │
         ▼
    ┌───┴───┐
    │Online?│
    └───┬───┘
        │
    ┌───┴───────────┐
    │               │
   YES              NO
    │               │
    ▼               ▼
Sync to         Queue for
Backend         later sync
    │               │
    │               │
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │ Navigate to   │
    │ Questionnaire │
    └───────────────┘
```

### 3. Login Flow

```
┌──────────────┐
│ LoginScreen  │
└──────┬───────┘
       │
       │ User enters:
       │ - Email
       │ - Password
       │
       ▼
┌────────────────────────────────┐
│ Check Network                  │
└────────┬───────────────────────┘
         │
    ┌────┴────┐
    │ Online? │
    └────┬────┘
         │
    ┌────┴──────────┐
    │               │
   YES              NO
    │               │
    ▼               ▼
┌─────────┐    ┌─────────────┐
│ Remote  │    │ Local Auth  │
│ Auth    │    │ (Offline)   │
└────┬────┘    └──────┬──────┘
     │                │
     │                │
     └────────┬───────┘
              │
              ▼
     ┌────────────────┐
     │ Verify Creds   │
     │ - Hash password│
     │ - Compare hash │
     └────┬───────────┘
          │
     ┌────┴────┐
     │ Valid?  │
     └────┬────┘
          │
    ┌─────┴─────┐
    │           │
   YES          NO
    │           │
    ▼           ▼
Generate    Show Error
JWT Token   "Invalid credentials"
    │
    ▼
Store Token
in Secure
Storage
    │
    ▼
Load User
Profile
    │
    ▼
Navigate to
Main App
```

### 4. Token Refresh Flow (Background)

```
App Running
    │
    ▼
┌────────────────────────────┐
│ Periodic Token Check       │
│ (every 5 minutes)          │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│ Is token expiring soon?    │
│ (< 15 minutes remaining)   │
└────────┬───────────────────┘
         │
    ┌────┴────┐
    │ YES     │ NO → Continue
    └────┬────┘
         │
         ▼
┌────────────────────────────┐
│ Call Refresh Token API     │
│ - Send refresh_token       │
│ - Receive new access_token │
└────────┬───────────────────┘
         │
    ┌────┴────┐
    │Success? │
    └────┬────┘
         │
    ┌────┴────────┐
    │             │
   YES            NO
    │             │
    ▼             ▼
Store New     Force Logout
Token         (token invalid)
    │
    ▼
Continue
```

### 5. Logout Flow

```
User taps "Logout"
    │
    ▼
┌────────────────────────────┐
│ Confirm Logout Dialog      │
│ "Unsaved changes will sync"│
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│ Sync Pending Changes       │
│ - Upload unsynced data     │
│ - Wait for confirmation    │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│ Revoke Session (Backend)   │
│ - Invalidate tokens        │
│ - Remove from sessions DB  │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│ Clear Local Session        │
│ - Delete from Secure Store │
│ - Clear current_user_id    │
│ - Reset ViewModel state    │
└────────┬───────────────────┘
         │
         ▼
┌────────────────────────────┐
│ Navigate to LoginScreen    │
└────────────────────────────┘
```

### 6. Multi-Device Sync Flow

```
Device A                           Backend                          Device B
   │                                  │                                 │
   │ Login                            │                                 │
   ├─────────────────────────────────>│                                 │
   │                                  │ Create session                  │
   │<─────────────────────────────────┤ Return tokens                   │
   │                                  │                                 │
   │ Modify sleep record              │                                 │
   │ (timestamp: 10:00)               │                                 │
   ├─────────────────────────────────>│                                 │
   │                                  │ Store with timestamp            │
   │                                  │ synced_at = 10:00               │
   │                                  │                                 │
   │                                  │                        Login    │
   │                                  │<────────────────────────────────┤
   │                                  │ Create session                  │
   │                                  │ Return tokens ─────────────────>│
   │                                  │                                 │
   │                                  │           Pull sync             │
   │                                  │<────────────────────────────────┤
   │                                  │                                 │
   │                                  │ Send all records ──────────────>│
   │                                  │ since last_sync_at              │
   │                                  │                                 │
   │ Modify same record               │       Modify same record        │
   │ (timestamp: 10:05)               │       (timestamp: 10:06)        │
   ├─────────────────────────────────>│                                 │
   │                                  │<────────────────────────────────┤
   │                                  │                                 │
   │                                  │ CONFLICT DETECTED!              │
   │                                  │ - Device A: updated_at = 10:05  │
   │                                  │ - Device B: updated_at = 10:06  │
   │                                  │                                 │
   │                                  │ Resolution: Last-Write-Wins     │
   │                                  │ Keep Device B version (newer)   │
   │                                  │                                 │
   │<─────────────────────────────────┤ Push Device B version ─────────>│
   │ Overwrite local with server      │ Confirm sync                    │
   │                                  │                                 │
```

---

## Database Schema Changes

### Migration V8: Authentication Tables

```sql
-- ============================================================================
-- Auth Sessions Table
-- ============================================================================
CREATE TABLE auth_sessions (
  id TEXT PRIMARY KEY,                    -- UUID
  user_id TEXT NOT NULL,
  device_id TEXT NOT NULL,                -- Unique device identifier
  device_name TEXT,                       -- "John's iPhone", "Work Laptop"

  -- Token information
  access_token_hash TEXT NOT NULL,        -- SHA-256 hash of JWT (for revocation)
  refresh_token_hash TEXT NOT NULL,       -- SHA-256 hash of refresh token
  token_expires_at TEXT NOT NULL,         -- ISO 8601 timestamp

  -- Session metadata
  ip_address TEXT,                        -- Last known IP
  user_agent TEXT,                        -- Browser/app info
  last_activity_at TEXT NOT NULL,         -- Last API call timestamp

  -- Session lifecycle
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,               -- Session hard expiry (30 days)
  revoked_at TEXT,                        -- NULL = active, timestamp = revoked

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_auth_sessions_user ON auth_sessions(user_id);
CREATE INDEX idx_auth_sessions_token_hash ON auth_sessions(access_token_hash);
CREATE INDEX idx_auth_sessions_active ON auth_sessions(user_id, revoked_at);

-- ============================================================================
-- Password Reset Tokens Table
-- ============================================================================
CREATE TABLE password_reset_tokens (
  id TEXT PRIMARY KEY,                    -- UUID
  user_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,               -- SHA-256 hash of reset token
  expires_at TEXT NOT NULL,               -- Valid for 1 hour
  used_at TEXT,                           -- NULL = unused, timestamp = used
  created_at TEXT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_password_reset_tokens_hash ON password_reset_tokens(token_hash);
CREATE INDEX idx_password_reset_tokens_user ON password_reset_tokens(user_id);

-- ============================================================================
-- Email Verification Tokens Table (Phase 2)
-- ============================================================================
CREATE TABLE email_verification_tokens (
  id TEXT PRIMARY KEY,                    -- UUID
  user_id TEXT NOT NULL,
  token_hash TEXT NOT NULL,               -- SHA-256 hash of verification token
  expires_at TEXT NOT NULL,               -- Valid for 24 hours
  verified_at TEXT,                       -- NULL = unverified, timestamp = verified
  created_at TEXT NOT NULL,

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_email_verification_tokens_hash ON email_verification_tokens(token_hash);
CREATE INDEX idx_email_verification_tokens_user ON email_verification_tokens(user_id);

-- ============================================================================
-- Sync Queue Table (for offline operations)
-- ============================================================================
CREATE TABLE sync_queue (
  id TEXT PRIMARY KEY,                    -- UUID
  user_id TEXT NOT NULL,
  operation_type TEXT NOT NULL,           -- 'CREATE', 'UPDATE', 'DELETE'
  table_name TEXT NOT NULL,               -- 'sleep_records', 'intervention_activities', etc.
  record_id TEXT NOT NULL,                -- ID of the record to sync
  payload TEXT NOT NULL,                  -- JSON payload of the operation

  -- Sync metadata
  created_at TEXT NOT NULL,               -- When queued
  attempts INTEGER DEFAULT 0,             -- Retry count
  last_attempt_at TEXT,                   -- Last sync attempt
  error_message TEXT,                     -- Last error (if failed)
  synced_at TEXT,                         -- NULL = pending, timestamp = synced

  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX idx_sync_queue_user ON sync_queue(user_id, synced_at);
CREATE INDEX idx_sync_queue_pending ON sync_queue(synced_at) WHERE synced_at IS NULL;
```

### Updates to Existing Users Table

```sql
-- Add authentication-related columns to existing users table
ALTER TABLE users ADD COLUMN email_verified INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN email_verified_at TEXT;
ALTER TABLE users ADD COLUMN last_login_at TEXT;
ALTER TABLE users ADD COLUMN failed_login_attempts INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN locked_until TEXT;  -- Account lockout (after N failed attempts)
```

---

## Security Implementation

### Password Hashing

**Library:** `argon2` (via `pointycastle` or native binding)

**Configuration:**
```dart
// Argon2id parameters
const argon2Params = Argon2Parameters(
  type: Argon2Type.id,         // Argon2id (hybrid)
  version: Argon2Version.v13,
  iterations: 3,               // Time cost
  memory: 65536,               // Memory cost (64 MB)
  parallelism: 4,              // Parallel threads
  saltLength: 16,              // 128-bit salt
);

// Hash password
String hashPassword(String password) {
  final salt = generateSalt(16);
  final argon2 = Argon2(argon2Params);
  final hash = argon2.generateBytes(password, salt, 32); // 256-bit hash

  // Store as: $argon2id$v=19$m=65536,t=3,p=4$salt$hash
  return encodeArgon2Hash(hash, salt, argon2Params);
}

// Verify password
bool verifyPassword(String password, String storedHash) {
  final params = decodeArgon2Hash(storedHash);
  final computedHash = hashPassword(password, params.salt);
  return secureCompare(computedHash, storedHash);
}
```

**Alternative (if Argon2 unavailable):** bcrypt with cost factor 12

### JWT Token Structure

**Access Token (expires in 15 minutes):**
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user-uuid-here",
    "email": "user@example.com",
    "iat": 1672531200,
    "exp": 1672532100,
    "jti": "token-uuid",
    "type": "access"
  }
}
```

**Refresh Token (expires in 30 days):**
```json
{
  "header": {
    "alg": "RS256",
    "typ": "JWT"
  },
  "payload": {
    "sub": "user-uuid-here",
    "iat": 1672531200,
    "exp": 1675123200,
    "jti": "refresh-token-uuid",
    "type": "refresh"
  }
}
```

### Secure Token Storage

**Use Flutter Secure Storage:**
```dart
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
);

// Store tokens
await storage.write(key: 'access_token', value: accessToken);
await storage.write(key: 'refresh_token', value: refreshToken);
await storage.write(key: 'token_expires_at', value: expiresAt.toIso8601String());

// Retrieve tokens
final accessToken = await storage.read(key: 'access_token');
```

### Security Best Practices

1. **Password Requirements:**
   - Minimum 8 characters
   - At least 1 uppercase letter
   - At least 1 lowercase letter
   - At least 1 number
   - At least 1 special character (optional but recommended)

2. **Account Lockout:**
   - Lock account after 5 failed login attempts
   - Lock duration: 15 minutes
   - Send email notification on lockout

3. **Rate Limiting (Backend):**
   - Login endpoint: 5 requests per minute per IP
   - Signup endpoint: 3 requests per hour per IP
   - Password reset: 3 requests per hour per email

4. **HTTPS Only:**
   - Enforce TLS 1.3
   - Certificate pinning (Phase 2)
   - Strict Transport Security headers

5. **Token Security:**
   - Access tokens expire in 15 minutes
   - Refresh tokens expire in 30 days
   - Refresh tokens rotated on each use
   - Revoke all tokens on password change

---

## Local-Remote Sync Strategy

### Sync Architecture

```
Local SQLite                Sync Queue              Backend PostgreSQL
─────────────              ────────────             ──────────────────
                               │
User creates sleep record      │
└─> INSERT into sleep_records  │
    synced_at = NULL           │
                               │
Queue sync operation           │
└─> INSERT into sync_queue     │
    operation_type = 'CREATE'  │
    table_name = 'sleep_records'
    payload = {record JSON}    │
    synced_at = NULL           │
                               │
                               │ When online:
                               │ Sync worker runs
                               │
                               ├─> POST /api/sync
                               │   Body: [sync_queue items]
                               │
                               │   Backend processes:
                               │   - Validate user auth
                               │   - Check for conflicts
                               │   - Insert/update records
                               │   - Return sync results
                               │
                               │<─ Response: {
                               │     synced: [record_ids],
                               │     conflicts: [conflicts],
                               │     errors: [errors]
                               │   }
                               │
Update local records           │
└─> UPDATE sleep_records       │
    SET synced_at = NOW()      │
    WHERE id IN (synced_ids)   │
                               │
Remove from queue              │
└─> UPDATE sync_queue          │
    SET synced_at = NOW()      │
    WHERE id IN (synced_ids)   │
```

### Conflict Resolution

**Last-Write-Wins (LWW) Strategy:**

```dart
class SyncConflictResolver {
  /// Resolve conflict using Last-Write-Wins
  ///
  /// Compares updated_at timestamps and keeps the newer version.
  SyncResolution resolveConflict(
    Map<String, dynamic> localRecord,
    Map<String, dynamic> remoteRecord,
  ) {
    final localUpdatedAt = DateTime.parse(localRecord['updated_at']);
    final remoteUpdatedAt = DateTime.parse(remoteRecord['updated_at']);

    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      // Remote is newer, overwrite local
      return SyncResolution(
        action: SyncAction.useRemote,
        record: remoteRecord,
        message: 'Remote version is newer',
      );
    } else if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      // Local is newer, push to server
      return SyncResolution(
        action: SyncAction.useLocal,
        record: localRecord,
        message: 'Local version is newer',
      );
    } else {
      // Exact same timestamp (rare), compare by other fields
      return SyncResolution(
        action: SyncAction.merge,
        record: mergeRecords(localRecord, remoteRecord),
        message: 'Merged conflicting versions',
      );
    }
  }
}
```

**Advanced Conflict Resolution (Phase 3):**
- Operational Transformation (OT)
- Conflict-free Replicated Data Types (CRDTs)
- User manual conflict resolution UI

### Sync Triggers

1. **Automatic Sync:**
   - On app foreground (every time app opens)
   - Every 15 minutes when app is active
   - After user makes changes (debounced 5 seconds)

2. **Manual Sync:**
   - Pull-to-refresh on any screen
   - Explicit "Sync Now" button in settings

3. **Background Sync:**
   - WorkManager (Android) / Background Fetch (iOS)
   - Runs every 4 hours when app is closed

### Sync Performance Optimization

1. **Delta Sync:**
   - Only sync records modified since last sync
   - Use `synced_at` timestamp for filtering

2. **Batch Operations:**
   - Send up to 100 records per request
   - Split large payloads into chunks

3. **Compression:**
   - GZIP compress request/response bodies
   - Reduces network usage by ~70%

4. **Retry Logic:**
   - Exponential backoff: 1s, 2s, 4s, 8s, 16s
   - Max 5 retry attempts
   - Queue failed syncs for later

---

## Multi-Device Considerations

### Device Registration

Each device is assigned a unique ID on first login:

```dart
Future<String> getDeviceId() async {
  // Check if device ID exists
  final prefs = await SharedPreferences.getInstance();
  String? deviceId = prefs.getString('device_id');

  if (deviceId == null) {
    // Generate new device ID
    deviceId = UuidGenerator.generate();
    await prefs.setString('device_id', deviceId);
  }

  return deviceId;
}
```

### Session Management

Users can view and revoke sessions from any device:

**Settings > Devices & Sessions:**
```
Your Devices
────────────────────────────────
📱 iPhone 14 Pro (This device)
   Last active: 2 minutes ago
   Location: San Francisco, CA

💻 MacBook Pro
   Last active: 2 hours ago
   Location: San Francisco, CA
   [Revoke Session]

📱 iPad Air
   Last active: 3 days ago
   Location: Los Angeles, CA
   [Revoke Session]
```

### Data Consistency Guarantees

1. **Eventual Consistency:**
   - All devices will eventually see the same data
   - May take seconds to minutes depending on network

2. **Conflict Detection:**
   - Server tracks `updated_at` timestamps
   - Conflicts resolved using Last-Write-Wins

3. **Data Integrity:**
   - Foreign key constraints enforced
   - Soft deletes prevent data loss
   - Sync queue ensures no operations are lost

---

## Implementation Phases

### Quick Status Reference

| Phase | Status | Completion Date | Backend Required | Key Features |
|-------|--------|----------------|------------------|--------------|
| **Phase 1: Local Auth** | ✅ Complete | 2025-12-29 | No | Signup, Login, Email Verification, Logout, PBKDF2 |
| **Phase 2: Backend + Sync** | ❌ Not Started | - | **Yes** | JWT tokens, API, Multi-device sync, Token refresh |
| **Phase 3: Advanced** | ❌ Not Started | - | **Yes** | Biometrics, OAuth, 2FA, Password reset |

---

### Phase 1: Local Authentication (MVP) ✅ COMPLETED (2025-12-29)

**Goal:** Replace current auto-login with proper local authentication

**Tasks:**
1. ✅ Add password hashing library (PBKDF2-HMAC-SHA256 via cryptography package)
2. ✅ Create LoginScreen and SignupScreen UI (+ AuthChoiceScreen)
3. ✅ Implement ViewModels for state management (LoginViewModel, SignupViewModel, EmailVerificationViewModel)
4. ✅ Create AuthRepository and EmailVerificationRepository
5. ✅ Add Migration V8 for email_verification_tokens table
6. ✅ Implement password validation logic (PasswordValidator with strength indicator)
7. ⏸️ Add Secure Storage - DEFERRED (not needed for local-only auth, JWT in Phase 2)
8. ✅ Fix logout flow (terminates app instead of dead-end)
9. ✅ Update SplashScreen to check authentication (routes to AuthChoiceScreen)
10. ⏸️ "Remember Me" functionality - DEFERRED (not needed for single-user local auth)
11. ✅ Write unit tests for auth logic (115+ tests covering all ViewModels and repositories)
12. ⏸️ Integration tests - DEFERRED (manual testing performed, integration tests in Phase 2)

**Deliverables:** ✅ ALL DELIVERED
- ✅ Working login/signup screens (AuthChoiceScreen, LoginScreen, SignupScreen)
- ✅ Password hashing implementation (PBKDF2 with 600,000 iterations)
- ✅ Email verification system (6-digit codes, 15-minute expiration)
- ✅ Local session management (SharedPreferences current_user_id)
- ✅ Fixed logout behavior (app termination + navigation fix)
- ✅ Test coverage: 115+ unit tests passing

**Database Changes:** ✅ COMPLETED
- ✅ Migration V8 (email_verification_tokens table + indexes)
- ✅ Updated users table (added email_verified column, password_hash field used)

**Documentation:**
- ✅ AUTH_DOCUMENTATION.md (complete implementation guide with flow diagrams)
- ✅ Updated README.md with auth status

---

### Phase 2: Remote Backend + Sync ❌ NOT STARTED (Requires Backend)

**Goal:** Add backend API and enable multi-device sync

**Status:** Blocked - Requires backend infrastructure to be built first

**Backend Tasks:**
1. ❌ Set up Node.js/Express (or NestJS) backend
2. ❌ Set up PostgreSQL database (schema mirrors SQLite)
3. ❌ Implement /auth/signup endpoint
4. ❌ Implement /auth/login endpoint (returns JWT tokens)
5. ❌ Implement /auth/refresh endpoint (token refresh)
6. ❌ Implement /auth/logout endpoint (invalidate refresh token)
7. ❌ Add JWT signing (RS256 with key rotation)
8. ❌ Add rate limiting middleware
9. ❌ Implement /sync endpoint for data sync
10. ❌ Add conflict resolution logic
11. ❌ Set up error logging (Sentry or similar)
12. ❌ Write API documentation (OpenAPI/Swagger)
13. ❌ Deploy to staging environment

**Mobile Tasks:**
1. ❌ Create AuthRemoteDataSource (API calls)
2. ❌ Update AuthRepository to use remote source
3. ❌ Add flutter_secure_storage for JWT token storage
4. ❌ Implement sync_queue mechanism
5. ❌ Add SyncWorker for background sync
6. ❌ Implement conflict resolution UI
7. ❌ Add network error handling
8. ❌ Add sync status indicators
9. ❌ Test offline-to-online scenarios
10. ❌ Add analytics for sync metrics
11. ❌ Implement automatic token refresh interceptor

**Deliverables:**
- Working backend API (not started)
- Multi-device sync (not started)
- JWT-based authentication (not started)
- Conflict resolution (not started)
- Backend deployed to staging (not started)
- API documentation (not started)

**Database Changes:**
- Migration V9 (sync_queue table) - not started
- Backend PostgreSQL schema - not started

---

### Phase 3: Enhanced Features ❌ NOT STARTED (Requires Phase 2 Backend)

**Goal:** Add biometric auth, OAuth, and advanced features

**Status:** Blocked - Requires Phase 2 backend to be completed first

**Tasks:**
1. ❌ Biometric authentication (fingerprint/face) via local_auth package
2. ❌ Google Sign-In integration (OAuth 2.0)
3. ❌ Apple Sign-In integration (OAuth 2.0)
4. ⏸️ Email verification flow - PARTIALLY DONE (local 6-digit codes implemented, backend email delivery pending)
5. ❌ Password reset via email (requires backend email service)
6. ❌ Two-factor authentication (2FA) via TOTP
7. ❌ Device management UI (view/revoke sessions)
8. ❌ Account deletion flow (with data export)
9. ❌ Export user data (GDPR compliance)
10. ❌ Improved conflict resolution (manual resolution UI)
11. ❌ Push notifications for sync status
12. ❌ Performance optimizations (delta sync, compression)

**Deliverables:**
- Biometric login support (not started)
- OAuth social login (not started)
- Backend email verification (local version complete)
- Password reset (not started)
- 2FA support (not started)
- Device management (not started)
- Account deletion (not started)
- GDPR compliance features

**Database Changes:**
- Migration V10 (email_verification_tokens)
- Migration V11 (two_factor_auth)

---

### Phase 4: Production Hardening - 2-3 weeks

**Goal:** Security audit, performance optimization, production deployment

**Tasks:**
1. ✅ Security audit (penetration testing)
2. ✅ Performance testing (load testing)
3. ✅ Fix security vulnerabilities
4. ✅ Optimize database queries
5. ✅ Add database indexes for performance
6. ✅ Set up monitoring (Datadog, New Relic)
7. ✅ Set up alerting (PagerDuty)
8. ✅ Write runbooks for common issues
9. ✅ Production deployment
10. ✅ Migration plan for existing users

**Deliverables:**
- Security audit report
- Performance benchmarks
- Production deployment
- Monitoring dashboards
- User migration completed

---

## Technical Stack

### Mobile (Flutter)

**Core:**
- Flutter 3.16+
- Dart 3.2+

**Authentication:**
- `flutter_secure_storage` ^9.0.0 - Secure token storage
- `local_auth` ^2.1.0 - Biometric authentication
- `google_sign_in` ^6.1.0 - Google OAuth
- `sign_in_with_apple` ^5.0.0 - Apple OAuth

**Password Hashing:**
- `pointycastle` ^3.7.0 - Cryptography (Argon2)
- OR `argon2_ffi_base` - Native Argon2 bindings

**HTTP & Sync:**
- `dio` ^5.4.0 - HTTP client
- `workmanager` ^0.5.1 - Background sync (Android)
- `background_fetch` ^1.2.0 - Background sync (iOS)

**State Management:**
- `provider` ^6.1.0 - Reactive state management

**Database:**
- `sqflite` ^2.3.0 - SQLite
- `path_provider` ^2.1.0 - File paths

**Utilities:**
- `uuid` ^4.2.0 - UUID generation
- `shared_preferences` ^2.2.0 - Key-value storage

### Backend

**Runtime:**
- Node.js 20 LTS
- TypeScript 5.3

**Framework:**
- NestJS 10.x (recommended) - Opinionated, enterprise-ready
- OR Express 4.x - Minimal, flexible

**Database:**
- PostgreSQL 15+ - Primary database
- Redis 7+ - Session storage, rate limiting

**Authentication:**
- `jsonwebtoken` - JWT signing/verification
- `bcrypt` OR `argon2` - Password hashing
- `passport` - Authentication middleware
- `passport-google-oauth20` - Google OAuth
- `passport-apple` - Apple OAuth

**API:**
- `class-validator` - Request validation
- `class-transformer` - DTO transformation
- `helmet` - Security headers
- `express-rate-limit` - Rate limiting
- `compression` - Response compression

**Monitoring:**
- `@sentry/node` - Error tracking
- `pino` - Structured logging
- `prometheus` - Metrics collection

**DevOps:**
- Docker - Containerization
- Docker Compose - Local development
- Kubernetes - Production orchestration (optional)

**Testing:**
- Jest - Unit/integration testing
- Supertest - API testing

---

## API Endpoints

### Authentication Endpoints

#### POST /api/auth/signup
Register a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "firstName": "John",
  "lastName": "Doe",
  "birthDate": "1990-01-15",
  "timezone": "America/Los_Angeles"
}
```

**Response (201 Created):**
```json
{
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "emailVerified": false
  },
  "tokens": {
    "accessToken": "eyJhbGciOiJSUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJSUzI1NiIs...",
    "expiresAt": "2025-12-29T12:15:00Z"
  }
}
```

**Errors:**
- `400 Bad Request` - Validation error (email format, password weak, etc.)
- `409 Conflict` - Email already registered
- `429 Too Many Requests` - Rate limit exceeded

---

#### POST /api/auth/login
Authenticate with email and password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "SecurePass123!",
  "deviceId": "uuid-device-id",
  "deviceName": "John's iPhone"
}
```

**Response (200 OK):**
```json
{
  "user": {
    "id": "uuid-here",
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe"
  },
  "tokens": {
    "accessToken": "eyJhbGciOiJSUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJSUzI1NiIs...",
    "expiresAt": "2025-12-29T12:15:00Z"
  },
  "session": {
    "id": "session-uuid",
    "deviceId": "uuid-device-id",
    "createdAt": "2025-12-29T12:00:00Z",
    "expiresAt": "2026-01-28T12:00:00Z"
  }
}
```

**Errors:**
- `401 Unauthorized` - Invalid credentials
- `423 Locked` - Account locked (too many failed attempts)
- `429 Too Many Requests` - Rate limit exceeded

---

#### POST /api/auth/refresh
Refresh access token using refresh token.

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJSUzI1NiIs..."
}
```

**Response (200 OK):**
```json
{
  "accessToken": "eyJhbGciOiJSUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJSUzI1NiIs...",
  "expiresAt": "2025-12-29T12:30:00Z"
}
```

**Errors:**
- `401 Unauthorized` - Invalid or expired refresh token

---

#### POST /api/auth/logout
Revoke current session and tokens.

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Request:**
```json
{
  "sessionId": "session-uuid"
}
```

**Response (204 No Content)**

**Errors:**
- `401 Unauthorized` - Invalid or missing token

---

#### POST /api/auth/logout-all
Revoke all sessions for current user (all devices).

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Response (204 No Content)**

---

### Sync Endpoints

#### POST /api/sync
Sync local changes to server and pull remote changes.

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Request:**
```json
{
  "deviceId": "uuid-device-id",
  "lastSyncAt": "2025-12-28T10:00:00Z",
  "operations": [
    {
      "id": "op-uuid-1",
      "type": "CREATE",
      "table": "sleep_records",
      "recordId": "record-uuid",
      "payload": {
        "id": "record-uuid",
        "userId": "user-uuid",
        "sleepDate": "2025-12-28",
        "totalSleepTime": 420,
        // ... other fields
        "createdAt": "2025-12-28T08:00:00Z",
        "updatedAt": "2025-12-28T08:00:00Z"
      }
    },
    {
      "id": "op-uuid-2",
      "type": "UPDATE",
      "table": "intervention_activities",
      "recordId": "activity-uuid",
      "payload": {
        "id": "activity-uuid",
        "wasCompleted": true,
        "completedAt": "2025-12-28T18:00:00Z",
        "updatedAt": "2025-12-28T18:05:00Z"
      }
    }
  ]
}
```

**Response (200 OK):**
```json
{
  "synced": [
    {
      "operationId": "op-uuid-1",
      "recordId": "record-uuid",
      "status": "success",
      "syncedAt": "2025-12-29T12:00:00Z"
    },
    {
      "operationId": "op-uuid-2",
      "recordId": "activity-uuid",
      "status": "conflict",
      "conflict": {
        "localUpdatedAt": "2025-12-28T18:05:00Z",
        "remoteUpdatedAt": "2025-12-28T18:10:00Z",
        "resolution": "remote_wins",
        "remoteRecord": { /* full record */ }
      }
    }
  ],
  "pullChanges": [
    {
      "table": "sleep_records",
      "recordId": "other-record-uuid",
      "operation": "UPDATE",
      "record": { /* full record */ }
    }
  ],
  "nextSyncAt": "2025-12-29T12:00:00Z"
}
```

**Errors:**
- `401 Unauthorized` - Invalid or expired token
- `400 Bad Request` - Invalid sync payload

---

#### GET /api/sync/status
Get current sync status and statistics.

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Response (200 OK):**
```json
{
  "lastSyncAt": "2025-12-29T12:00:00Z",
  "pendingOperations": 0,
  "totalRecords": 145,
  "recordCounts": {
    "sleepRecords": 30,
    "interventionActivities": 90,
    "userModuleConfigurations": 5,
    "userSleepBaselines": 20
  }
}
```

---

### User Management Endpoints

#### GET /api/users/me
Get current user profile.

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Response (200 OK):**
```json
{
  "id": "uuid-here",
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "birthDate": "1990-01-15",
  "timezone": "America/Los_Angeles",
  "emailVerified": true,
  "createdAt": "2025-01-01T00:00:00Z",
  "updatedAt": "2025-12-29T12:00:00Z"
}
```

---

#### PATCH /api/users/me
Update current user profile.

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Request:**
```json
{
  "firstName": "John",
  "lastName": "Smith",
  "timezone": "America/New_York"
}
```

**Response (200 OK):** (updated user object)

---

#### POST /api/users/change-password
Change password for authenticated user.

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Request:**
```json
{
  "currentPassword": "OldPass123!",
  "newPassword": "NewSecurePass456!"
}
```

**Response (204 No Content)**

**Side Effects:**
- All sessions except current are revoked
- All refresh tokens are invalidated

---

#### GET /api/users/sessions
List all active sessions for current user.

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Response (200 OK):**
```json
{
  "sessions": [
    {
      "id": "session-uuid-1",
      "deviceId": "device-uuid-1",
      "deviceName": "John's iPhone",
      "lastActivityAt": "2025-12-29T12:00:00Z",
      "ipAddress": "192.168.1.100",
      "isCurrent": true,
      "createdAt": "2025-12-01T10:00:00Z",
      "expiresAt": "2026-01-01T10:00:00Z"
    },
    {
      "id": "session-uuid-2",
      "deviceId": "device-uuid-2",
      "deviceName": "MacBook Pro",
      "lastActivityAt": "2025-12-28T18:00:00Z",
      "ipAddress": "192.168.1.101",
      "isCurrent": false,
      "createdAt": "2025-11-15T09:00:00Z",
      "expiresAt": "2025-12-15T09:00:00Z"
    }
  ]
}
```

---

#### DELETE /api/users/sessions/:sessionId
Revoke a specific session.

**Request Headers:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Response (204 No Content)**

---

## Testing Strategy

### Unit Tests

**Auth Logic:**
- Password hashing and verification
- Token generation and validation
- Session creation and management
- Password strength validation

**Sync Logic:**
- Conflict detection
- Conflict resolution algorithms
- Queue management
- Retry logic

**ViewModels:**
- Login state transitions
- Signup validation
- Error handling
- Loading states

### Integration Tests

**Auth Flows:**
- Complete signup flow
- Complete login flow
- Token refresh flow
- Logout flow
- Password reset flow

**Sync Flows:**
- Create record → Sync to server
- Update record → Conflict resolution
- Delete record → Soft delete sync
- Offline queue → Online sync

### End-to-End Tests

**Multi-Device Scenarios:**
- Login on Device A
- Login on Device B
- Create record on Device A
- Sync to server
- Pull on Device B
- Verify record appears

**Offline Scenarios:**
- Create record while offline
- Attempt sync (should queue)
- Go online
- Verify automatic sync

### Security Tests

**Penetration Testing:**
- SQL injection attempts
- XSS attacks
- CSRF attacks
- JWT tampering
- Password brute force
- Rate limit bypass

**Load Testing:**
- 1000 concurrent logins
- 10,000 sync operations per minute
- Token refresh under load
- Database connection pooling

---

## Migration Path

### Migrating Existing Users

**Step 1: Database Migration**
```dart
Future<void> migrateExistingUsers() async {
  final db = await DatabaseHelper.instance.database;

  // Run Migration V8 (adds auth_sessions table)
  await db.execute(MIGRATION_V8);

  // Update existing users to add auth fields
  await db.execute('''
    UPDATE users
    SET email_verified = 1,
        email_verified_at = datetime('now')
    WHERE email != 'default@sleepbalance.app';
  ''');
}
```

**Step 2: Prompt for Password**

On first launch after update, show password setup screen:

```
┌────────────────────────────────────┐
│  Welcome Back!                     │
│                                    │
│  We've added account security.     │
│  Please set a password to          │
│  continue.                         │
│                                    │
│  Email: user@example.com           │
│  Password: [_________________]     │
│  Confirm:  [_________________]     │
│                                    │
│  [ Continue ]                      │
└────────────────────────────────────┘
```

**Step 3: Create Auth Session**

After password is set:
1. Hash password and update database
2. Generate JWT tokens
3. Store in Secure Storage
4. Mark user as migrated
5. Continue to main app

**Step 4: Background Sync**

After migration:
1. Queue all unsynced records
2. Attempt backend sync
3. Show sync progress notification
4. Handle any conflicts

---

## Conclusion

This authentication plan provides a comprehensive roadmap for implementing a secure, scalable, and user-friendly authentication system in SleepBalance. The phased approach allows for iterative development and testing while maintaining backward compatibility with existing users.

**Key Takeaways:**
- ✅ Local-first architecture ensures offline functionality
- ✅ JWT-based authentication provides security and scalability
- ✅ Multi-device sync enables seamless user experience
- ✅ Phased implementation reduces risk and allows for testing
- ✅ Migration path ensures no data loss for existing users

**Next Steps:**
1. Review and approve this plan
2. Set up development environment
3. Begin Phase 1 implementation
4. Schedule security review after Phase 1
5. Plan backend infrastructure for Phase 2

---

**Document History:**
- v1.0 (2025-12-29): Initial draft
