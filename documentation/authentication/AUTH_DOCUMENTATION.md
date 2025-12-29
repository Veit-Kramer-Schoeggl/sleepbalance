# SleepBalance Authentication Documentation

## Table of Contents

1. [Overview](#overview)
2. [Authentication Flow Diagrams](#authentication-flow-diagrams)
3. [FR-1: User Registration with Email Verification](#fr-1-user-registration-with-email-verification)
4. [FR-2: User Login](#fr-2-user-login)
5. [Technical Architecture](#technical-architecture)
6. [Security Implementation](#security-implementation)
7. [Testing](#testing)
8. [File Structure](#file-structure)

---

## Overview

SleepBalance implements a **local-first authentication system** with email verification. The system is designed for offline-first operation with no backend API required in Phase 1 (MVP).

### Key Features

- **Local Password Storage**: PBKDF2-HMAC-SHA256 with 600,000 iterations
- **Email Verification**: 6-digit codes with 15-minute expiration
- **Offline Capability**: All authentication works without internet connection
- **Session Management**: SharedPreferences for current user tracking
- **Clean Architecture**: MVVM pattern with clear separation of concerns

### Current Status

- ✅ **FR-1 Completed**: User Registration with Email Verification
- ✅ **FR-2 Completed**: User Login with Password Verification
- ⏸️ **FR-3 Pending**: Backend Integration (Phase 2)
- ⏸️ **FR-4 Pending**: OAuth & Social Login (Phase 3)

---

## Authentication Flow Diagrams

### Complete First Launch Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                           App Startup                                │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
                                ▼
                         ┌─────────────┐
                         │ SplashScreen│
                         └──────┬──────┘
                                │
                   ┌────────────┴───────────┐
                   │ Check logged in?       │
                   └────────┬───────────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
             NO                          YES
              │                           │
              ▼                           ▼
    ┌──────────────────┐        ┌────────────────┐
    │ AuthChoiceScreen │        │ Check Email    │
    │                  │        │ Verified?      │
    └────────┬─────────┘        └────┬───────────┘
             │                       │
    ┌────────┴────────┐         ┌───┴────────┐
    │                 │         │            │
"Login"         "Register"    YES           NO
    │                 │         │            │
    ▼                 ▼         │            ▼
┌──────────┐    ┌──────────┐   │    ┌──────────────┐
│  Login   │    │  Signup  │   │    │ AuthChoice   │
│  Screen  │    │  Screen  │   │    │ Screen       │
└────┬─────┘    └────┬─────┘   │    └──────────────┘
     │               │          │
     │               ▼          │
     │       ┌──────────────┐  │
     │       │ Email Verify │  │
     │       │ Screen       │  │
     │       └──────┬───────┘  │
     │              │           │
     │              │           │
     │              ▼           │
     │      ┌──────────────┐   │
     │      │Questionnaire │   │
     │      │   Screen     │   │
     │      │(Always for   │   │
     │      │registration) │   │
     │      └──────┬───────┘   │
     │             │            │
     │             ▼            │
     │      ┌──────────────┐   │
     │      │     Main     │   │
     │      │  Navigation  │   │
     │      └──────────────┘   │
     │                          │
     └──────┬───────────────────┘
            │
            ▼
    ┌───────────────┐
    │ First Launch? │
    └───────┬───────┘
            │
       ┌────┴─────┐
       │          │
      YES        NO
       │          │
       ▼          ▼
┌──────────────┐ ┌──────────────┐
│Questionnaire │ │     Main     │
│   Screen     │ │  Navigation  │
└──────────────┘ └──────────────┘
```

### Registration Flow (FR-1)

```
┌──────────────────────────────────────────────────────────────────┐
│                      User Registration                            │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
                   ┌──────────────────┐
                   │  SignupScreen    │
                   │  (Form Input)    │
                   └────────┬─────────┘
                            │
                            │ User enters:
                            │ - First Name, Last Name
                            │ - Email
                            │ - Password (with strength indicator)
                            │ - Birth Date
                            │ - Timezone (auto-detected)
                            ▼
                   ┌──────────────────┐
                   │ Validate Input   │
                   └────────┬─────────┘
                            │
                   ┌────────┴────────┐
                   │ Password Valid? │
                   └────────┬────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
             NO                          YES
              │                           │
              ▼                           ▼
      ┌──────────────┐         ┌──────────────────┐
      │ Show Error   │         │ Check Email      │
      │ (Requirements│         │ Already Exists?  │
      │  Not Met)    │         └────────┬─────────┘
      └──────────────┘                  │
                               ┌────────┴────────┐
                               │                 │
                              NO                YES
                               │                 │
                               ▼                 ▼
                    ┌─────────────────┐  ┌──────────────┐
                    │ Hash Password   │  │ Show Error   │
                    │ (PBKDF2)        │  │ "Email Exists│
                    └────────┬────────┘  └──────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Save User to DB │
                    │ (emailVerified: │
                    │     false)      │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Generate 6-Digit│
                    │ Verification    │
                    │ Code (15 min)   │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Display Code    │
                    │ (Test Mode Only)│
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────────┐
                    │ Navigate to         │
                    │ EmailVerification   │
                    │ Screen              │
                    └─────────────────────┘
```

### Login Flow (FR-2)

```
┌──────────────────────────────────────────────────────────────────┐
│                         User Login                                │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
                   ┌──────────────────┐
                   │  LoginScreen     │
                   │  (Email/Pass)    │
                   └────────┬─────────┘
                            │
                            │ User enters:
                            │ - Email
                            │ - Password
                            ▼
                   ┌──────────────────┐
                   │ Validate Input   │
                   │ (Not empty)      │
                   └────────┬─────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
           Invalid                      Valid
              │                           │
              ▼                           ▼
      ┌──────────────┐         ┌──────────────────┐
      │ Show Error   │         │ Lookup User by   │
      │ "Enter Email │         │ Email            │
      │  & Password" │         └────────┬─────────┘
      └──────────────┘                  │
                               ┌────────┴────────┐
                               │                 │
                           Not Found           Found
                               │                 │
                               ▼                 ▼
                      ┌──────────────┐  ┌──────────────────┐
                      │ Show Error   │  │ Verify Password  │
                      │ "No Account  │  │ Hash (PBKDF2)    │
                      │  Found"      │  └────────┬─────────┘
                      └──────────────┘           │
                                        ┌────────┴────────┐
                                        │                 │
                                    Invalid            Valid
                                        │                 │
                                        ▼                 ▼
                               ┌──────────────┐  ┌──────────────────┐
                               │ Show Error   │  │ Check Email      │
                               │ "Incorrect   │  │ Verified?        │
                               │  Password"   │  └────────┬─────────┘
                               └──────────────┘           │
                                               ┌──────────┴──────────┐
                                               │                     │
                                              NO                    YES
                                               │                     │
                                               ▼                     ▼
                                      ┌──────────────┐    ┌──────────────────┐
                                      │ Show Error   │    │ Set Current User │
                                      │ "Verify Your │    │ (SharedPrefs)    │
                                      │  Email"      │    └────────┬─────────┘
                                      └──────────────┘             │
                                                                   ▼
                                                          ┌──────────────────┐
                                                          │ First Launch?    │
                                                          └────────┬─────────┘
                                                                   │
                                                          ┌────────┴────────┐
                                                          │                 │
                                                         YES               NO
                                                          │                 │
                                                          ▼                 ▼
                                                   ┌─────────────┐  ┌─────────────┐
                                                   │Questionnaire│  │    Main     │
                                                   │   Screen    │  │ Navigation  │
                                                   └─────────────┘  └─────────────┘
```

### Logout Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                         User Logout                               │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
                   ┌──────────────────┐
                   │  Settings Screen │
                   │  "Logout" Button │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Clear current_   │
                   │ user_id from     │
                   │ SharedPrefs      │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Reset ViewModel  │
                   │ State            │
                   │ (currentUser=null│
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Notify Listeners │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ Terminate App    │
                   │ (SystemNavigator │
                   │  .pop())         │
                   └────────┬─────────┘
                            │
                            ▼
                   ┌──────────────────┐
                   │ User relaunches  │
                   │ app → Shows      │
                   │ AuthChoiceScreen │
                   └──────────────────┘
```

### Email Verification Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    Email Verification                             │
└────────────────────────────┬─────────────────────────────────────┘
                             │
                             ▼
                   ┌─────────────────────┐
                   │ EmailVerification   │
                   │ Screen              │
                   │ (Shows timer)       │
                   └────────┬────────────┘
                            │
                            ▼
                   ┌─────────────────────┐
                   │ User enters 6-digit │
                   │ verification code   │
                   └────────┬────────────┘
                            │
                            ▼
                   ┌─────────────────────┐
                   │ Validate Format     │
                   │ (6 digits, numeric) │
                   └────────┬────────────┘
                            │
              ┌─────────────┴─────────────┐
              │                           │
           Invalid                      Valid
              │                           │
              ▼                           ▼
      ┌──────────────┐         ┌──────────────────┐
      │ Show Error   │         │ Verify Code in   │
      │ "6-digit code│         │ Database         │
      │  required"   │         └────────┬─────────┘
      └──────────────┘                  │
                               ┌────────┴────────┐
                               │                 │
                        Code Invalid         Code Valid
                        or Expired           & Not Used
                               │                 │
                               ▼                 ▼
                      ┌──────────────┐  ┌──────────────────┐
                      │ Show Error   │  │ Mark Code as     │
                      │ "Invalid or  │  │ Used             │
                      │  Expired"    │  └────────┬─────────┘
                      └──────────────┘           │
                                                 ▼
                                        ┌──────────────────┐
                                        │ Mark Email as    │
                                        │ Verified in DB   │
                                        └────────┬─────────┘
                                                 │
                                                 ▼
                                        ┌──────────────────┐
                                        │ Set Current User │
                                        │ (SharedPrefs)    │
                                        └────────┬─────────┘
                                                 │
                                                 ▼
                                        ┌──────────────────┐
                                        │ Navigate to      │
                                        │ Questionnaire    │
                                        └──────────────────┘
```

---

## FR-1: User Registration with Email Verification

### Feature Overview

Allows new users to create an account with email and password. Email verification is required before accessing the app.

### Implementation Details

**Date Completed**: Phase 1 (MVP)
**Status**: ✅ Completed

#### Components

1. **SignupScreen** (`lib/features/auth/presentation/screens/signup_screen.dart`)
   - Form with input fields:
     - First Name (required)
     - Last Name (required)
     - Email (validated format)
     - Password (with strength indicator)
     - Birth Date (date picker)
     - Timezone (auto-detected, read-only)
   - Real-time password strength indicator
   - Password requirements checklist (8+ chars, uppercase, lowercase, number)
   - Form validation before submission

2. **SignupViewModel** (`lib/features/auth/presentation/viewmodels/signup_viewmodel.dart`)
   - Business logic for user registration
   - Password validation using PasswordValidator
   - Password strength calculation
   - User creation with PBKDF2 password hashing
   - Email verification code generation
   - State management (loading, errors, created user)

3. **EmailVerificationScreen** (`lib/features/auth/presentation/screens/email_verification_screen.dart`)
   - 6-digit code input
   - 15-minute countdown timer
   - Code resend functionality
   - Real-time validation
   - Success/error feedback

4. **EmailVerificationViewModel** (`lib/features/auth/presentation/viewmodels/email_verification_viewmodel.dart`)
   - Code verification logic
   - Timer management
   - Code resend handling
   - Email verification status update
   - Automatic current user setting on success

#### Password Requirements

- **Minimum Length**: 8 characters
- **Uppercase**: At least 1 uppercase letter (A-Z)
- **Lowercase**: At least 1 lowercase letter (a-z)
- **Number**: At least 1 number (0-9)
- **Special Characters**: Recommended but optional

#### Password Strength Levels

- **Weak**: Does not meet basic requirements
- **Medium**: Meets basic requirements but short or simple
- **Strong**: Meets all requirements with good length (10+ chars)

#### Email Verification Process

1. **Code Generation**:
   - 6-digit random numeric code
   - Stored in `email_verification_tokens` table
   - Expires after 15 minutes
   - Previous codes for same email are invalidated

2. **Test Mode**:
   - Code displayed on screen after registration (for testing)
   - Will be removed in production (Phase 2 - backend integration)

3. **Code Verification**:
   - Format validation (6 digits, numeric)
   - Database lookup (email + code + expiration + not used)
   - Marks code as used after successful verification
   - Sets `emailVerified = true` in users table
   - Sets user as current user in SharedPreferences

4. **Code Resend**:
   - Generates new 6-digit code
   - Invalidates previous code
   - Resets 15-minute timer

#### Database Schema (Migration V8)

**email_verification_tokens table**:
```sql
CREATE TABLE email_verification_tokens (
  id TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  code TEXT NOT NULL,
  created_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  verified_at TEXT,
  is_used INTEGER DEFAULT 0,
  INDEX idx_email_verification_email (email),
  INDEX idx_email_verification_expires (expires_at)
);
```

**users table update**:
```sql
ALTER TABLE users ADD COLUMN email_verified INTEGER DEFAULT 0;
```

#### Error Handling

- **Email Already Exists**: Shows error message
- **Invalid Password**: Shows requirements not met
- **Network Issues**: Handled gracefully (local-first)
- **Invalid Verification Code**: Clear error message
- **Expired Code**: Prompt to resend

#### Testing

**Unit Tests**:
- ✅ SignupViewModel tests (16 tests)
- ✅ EmailVerificationViewModel tests (19 tests)
- ✅ PasswordValidator tests (24 tests)
- ✅ Email verification repository tests (18 tests)
- ✅ Migration V8 tests (8 tests)

**Total**: 85+ test cases covering registration and verification

---

## FR-2: User Login

### Feature Overview

Allows existing users to authenticate with email and password. Requires email verification before access.

### Implementation Details

**Date Completed**: Phase 1 (MVP)
**Status**: ✅ Completed

#### Components

1. **AuthChoiceScreen** (`lib/features/auth/presentation/screens/auth_choice_screen.dart`)
   - Landing screen for unauthenticated users
   - "Login" button → navigates to LoginScreen
   - "Create Account" button → navigates to SignupScreen
   - App branding (logo, name, tagline)
   - Clean, centered UI design

2. **LoginScreen** (`lib/features/auth/presentation/screens/login_screen.dart`)
   - Email input field (validated)
   - Password input field (with visibility toggle)
   - Login button (with loading indicator)
   - Error message display
   - Form validation

3. **LoginViewModel** (`lib/features/auth/presentation/viewmodels/login_viewmodel.dart`)
   - Authentication logic
   - Email/password validation
   - User lookup by email
   - PBKDF2 password verification
   - Email verification status check
   - Session management (sets current user)
   - State management (loading, errors, authenticated user)

#### Authentication Process

1. **Input Validation**:
   - Email not empty
   - Password not empty
   - Email format validation (contains @ and .)

2. **User Lookup**:
   - Search database for user by email
   - Return error if user not found

3. **Password Verification**:
   - Extract password hash from user record
   - Verify password using PBKDF2 with stored hash
   - Constant-time comparison (prevents timing attacks)

4. **Email Verification Check**:
   - Check `emailVerified` flag in user record
   - Reject login if email not verified
   - Prompt user to verify email

5. **Session Creation**:
   - Set `current_user_id` in SharedPreferences
   - Update ViewModel state with authenticated user
   - Navigate to appropriate screen

#### Navigation After Login

Login uses conditional navigation based on questionnaire completion:

- **First Launch = true** (Questionnaire not completed): Navigate to QuestionnaireScreen
  - Edge case: User registered, verified email, but closed app before completing questionnaire
- **First Launch = false** (Questionnaire completed): Navigate to MainNavigation
  - Normal returning user flow

Determined by `PreferencesService.isFirstLaunch()` flag, which is set to `false` after questionnaire completion.

#### Logout Implementation

**File**: `lib/features/settings/presentation/viewmodels/settings_viewmodel.dart`

**Process**:
1. Clear `current_user_id` from SharedPreferences
2. Reset ViewModel state (`currentUser = null`)
3. Notify listeners
4. **Terminate app** using `SystemNavigator.pop()`

**Behavior**:
- App closes completely on logout
- Next launch shows AuthChoiceScreen
- User data persists in database (not deleted)

#### Error Messages

For security (prevent user enumeration):
- ❌ **Bad**: "User exists but password is wrong"
- ✅ **Good**: "Incorrect password"
- ✅ **Good**: "No account found with this email address"

Generic errors prevent attackers from determining valid email addresses.

#### Testing

**Unit Tests**:
- ✅ LoginViewModel tests (12 tests)
  - Successful login
  - Empty field validation
  - User not found
  - Invalid password
  - Email not verified
  - Loading state management
  - Exception handling
  - Error clearing

**Total**: 12 comprehensive test cases

---

## Technical Architecture

### MVVM Pattern

```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                    │
│  ┌──────────────┐        ┌──────────────────────────────┐   │
│  │   Screens    │◄───────│      ViewModels              │   │
│  │  (Widgets)   │        │  (Business Logic + State)    │   │
│  └──────────────┘        └──────────┬───────────────────┘   │
│                                     │                        │
└─────────────────────────────────────┼────────────────────────┘
                                      │
                                      │ Uses
                                      ▼
┌─────────────────────────────────────────────────────────────┐
│                         Domain Layer                         │
│  ┌──────────────┐        ┌──────────────────────────────┐   │
│  │  Repositories│        │      Models                  │   │
│  │ (Interfaces) │        │  (User, EmailVerification)   │   │
│  └──────┬───────┘        └──────────────────────────────┘   │
│         │                                                    │
└─────────┼────────────────────────────────────────────────────┘
          │
          │ Implemented by
          ▼
┌─────────────────────────────────────────────────────────────┐
│                          Data Layer                          │
│  ┌──────────────────────┐      ┌──────────────────────┐     │
│  │  Repository Impls    │      │   Data Sources       │     │
│  │  (UserRepository,    │─────►│  (Local Database)    │     │
│  │   AuthRepository)    │      │  (SharedPreferences) │     │
│  └──────────────────────┘      └──────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### State Management

**Provider Pattern**:
- Global `SettingsViewModel` for user state
- Local ViewModels for auth screens (LoginViewModel, SignupViewModel)
- `ChangeNotifier` for reactive UI updates
- `notifyListeners()` triggers UI rebuild

**Example**:
```dart
// Global provider (main.dart)
ChangeNotifierProvider<SettingsViewModel>(
  create: (_) => SettingsViewModel(repository: userRepository),
)

// Local provider (LoginScreen)
ChangeNotifierProvider(
  create: (_) => LoginViewModel(userRepository: context.read()),
  child: _LoginScreenContent(),
)

// UI listens to changes
Consumer<LoginViewModel>(
  builder: (context, viewModel, _) {
    if (viewModel.isLoading) return CircularProgressIndicator();
    // ...
  },
)
```

### Database Structure

**SQLite Database** (`database_helper.dart`)

**Tables**:
1. `users` - User profiles and credentials
2. `email_verification_tokens` - Verification codes
3. (Additional tables for sleep data, wearables, etc.)

**Key Relationships**:
- Users have many verification tokens (email)
- Users have many sleep records (foreign key: user_id)

---

## Security Implementation

### Password Hashing (PBKDF2)

**Algorithm**: PBKDF2-HMAC-SHA256
**Implementation**: Pure Dart (`cryptography` package)
**File**: `lib/features/auth/data/services/password_hash_service.dart`

#### Parameters

- **Iterations**: 600,000 (OWASP 2023 recommendation)
- **Salt Length**: 16 bytes (cryptographically random)
- **Hash Length**: 32 bytes
- **Algorithm**: HMAC-SHA256

#### Hash Format (PHC-Inspired)

```
$pbkdf2-sha256$v=1$i=600000$<base64_salt>$<base64_hash>
```

**Example**:
```
$pbkdf2-sha256$v=1$i=600000$VGVzdFNhbHQxMjM0NTY3OA==$6FxnM8k3vY0Hq+CZK5gJYwL3z2NxT9pR8dW4mA7fEhI=
```

#### Operations

**Hashing**:
```dart
final hash = await PasswordHashService.hashPassword('MyPassword123');
// Stores in database
```

**Verification**:
```dart
final isValid = await PasswordHashService.verifyPassword(
  'MyPassword123',
  storedHash,
);
```

**Rehashing Check**:
```dart
if (PasswordHashService.needsRehash(storedHash)) {
  // Update to new parameters
}
```

#### Security Features

1. **Random Salt**: Each password gets unique 16-byte salt
2. **High Iteration Count**: 600,000 iterations (slow for attackers)
3. **Constant-Time Comparison**: Prevents timing attacks
4. **No Plain Text Storage**: Passwords never stored or logged
5. **Automatic Parameter Upgrade**: `needsRehash()` detects outdated hashes

### Session Management

**Storage**: SharedPreferences
**Key**: `current_user_id`
**Type**: String (user UUID)

**Security Considerations**:
- Only user ID stored (not password or sensitive data)
- Cleared on logout
- App terminates after logout (prevents memory leaks)

### Email Verification Security

1. **Code Expiration**: 15 minutes
2. **Single Use**: Code marked as used after verification
3. **Code Invalidation**: New code invalidates previous codes
4. **Rate Limiting**: Future consideration (Phase 2)

### Error Message Security

**Principle**: Don't reveal user existence

**Bad Examples**:
- ❌ "User exists but password wrong" (reveals valid email)
- ❌ "Email not registered" (reveals invalid email)

**Good Examples**:
- ✅ "No account found with this email address" (generic)
- ✅ "Incorrect password" (doesn't confirm email exists)
- ✅ "Login failed. Please try again." (very generic for errors)

---

## Testing

### Unit Tests

**Coverage by Feature**:

| Feature | Test File | Test Count | Status |
|---------|-----------|------------|--------|
| Password Validation | `password_validator_test.dart` | 24 | ✅ Passing |
| Password Hashing | `password_hash_service_test.dart` | 13 | ✅ Passing |
| Signup ViewModel | `signup_viewmodel_test.dart` | 16 | ✅ Passing |
| Login ViewModel | `login_viewmodel_test.dart` | 12 | ✅ Passing |
| Email Verification VM | `email_verification_viewmodel_test.dart` | 19 | ✅ Passing |
| Email Verification Repo | `email_verification_repository_impl_test.dart` | 18 | ✅ Passing |
| Migration V8 | `migration_v8_test.dart` | 8 | ✅ Passing |
| Auth Repository | `auth_repository_impl_test.dart` | 5 | ✅ Passing |

**Total**: **115+ unit tests** covering authentication

### Running Tests

```bash
# Run all auth tests
flutter test test/features/auth/

# Run specific test file
flutter test test/features/auth/presentation/viewmodels/login_viewmodel_test.dart

# Run with coverage
flutter test --coverage
```

### Manual Testing Checklist

#### Registration Flow
- [ ] Form validation works (empty fields, invalid email)
- [ ] Password strength indicator updates in real-time
- [ ] Password requirements checklist shows correct status
- [ ] Date picker works and validates age
- [ ] Timezone auto-detection works
- [ ] Duplicate email shows error
- [ ] Successful registration shows verification screen

#### Email Verification
- [ ] Timer counts down correctly
- [ ] Code format validation works (6 digits)
- [ ] Valid code verifies successfully
- [ ] Invalid code shows error
- [ ] Expired code shows error
- [ ] Resend code generates new code and resets timer
- [ ] Successful verification navigates to questionnaire

#### Login Flow
- [ ] Email validation works
- [ ] Password visibility toggle works
- [ ] Empty fields show error
- [ ] Invalid email shows "No account found"
- [ ] Wrong password shows "Incorrect password"
- [ ] Unverified email shows verification error
- [ ] Valid login navigates to main app (or questionnaire if first launch)

#### Logout Flow
- [ ] Logout button in Settings works
- [ ] App terminates after logout
- [ ] Reopening app shows AuthChoiceScreen
- [ ] Can login again with same credentials

#### AuthChoiceScreen
- [ ] Login button navigates to LoginScreen
- [ ] Create Account button navigates to SignupScreen
- [ ] UI displays correctly (logo, tagline, buttons)

### Troubleshooting Authentication Issues

If you encounter authentication-related database errors (migration conflicts, schema issues, user verification problems):

**See**: [Database Troubleshooting Guide](../database/DATABASE.md#troubleshooting)

Common authentication database issues:
- `duplicate column name: email_verified` → Database reset required
- Email verification not working → Check database version (requires v8+)
- Login fails with database errors → Clear database and reseed test data

The database documentation provides methods for:
1. **Uninstall/reinstall** (cleanest approach)
2. **Clear DB button** (dev tools on auth screen)
3. **Manual database deletion** (advanced)

After resetting, use the "Seed DB" button to create test user: `testuser1@gmail.com` / `1234`

---

## File Structure

### Directory Layout

```
lib/features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_local_datasource.dart
│   │   └── email_verification_local_datasource.dart
│   ├── repositories/
│   │   ├── auth_repository_impl.dart
│   │   └── email_verification_repository_impl.dart
│   └── services/
│       └── password_hash_service.dart            # PBKDF2 implementation
├── domain/
│   ├── models/
│   │   ├── email_verification.dart               # Verification code model
│   │   └── auth_exceptions.dart                  # Custom exceptions
│   ├── repositories/
│   │   ├── auth_repository.dart                  # Auth interface
│   │   └── email_verification_repository.dart    # Verification interface
│   └── validators/
│       └── password_validator.dart               # Password validation logic
└── presentation/
    ├── screens/
    │   ├── auth_choice_screen.dart               # Login/Register choice
    │   ├── login_screen.dart                     # Login UI
    │   ├── signup_screen.dart                    # Registration UI
    │   └── email_verification_screen.dart        # Verification UI
    ├── viewmodels/
    │   ├── login_viewmodel.dart                  # Login state & logic
    │   ├── signup_viewmodel.dart                 # Signup state & logic
    │   └── email_verification_viewmodel.dart     # Verification state & logic
    └── widgets/
        └── password_strength_indicator.dart      # UI component

lib/features/settings/
├── domain/
│   ├── models/
│   │   └── user.dart                             # User model
│   └── repositories/
│       └── user_repository.dart                  # User CRUD interface
├── data/
│   ├── datasources/
│   │   └── user_local_datasource.dart
│   └── repositories/
│       └── user_repository_impl.dart
└── presentation/
    ├── screens/
    │   └── settings_screen.dart                  # Settings UI with logout
    └── viewmodels/
        └── settings_viewmodel.dart               # Global user state

lib/shared/
├── screens/app/
│   └── splash_screen.dart                        # App entry navigation
└── services/storage/
    └── preferences_service.dart                  # SharedPreferences wrapper

lib/core/database/
├── database_helper.dart                          # SQLite setup
└── migrations/
    └── migration_v8.dart                         # Email verification tables

test/features/auth/
├── data/
│   ├── repositories/
│   │   ├── auth_repository_impl_test.dart
│   │   └── email_verification_repository_impl_test.dart
│   └── services/
│       └── password_hash_service_test.dart
├── domain/
│   └── validators/
│       └── password_validator_test.dart
└── presentation/
    └── viewmodels/
        ├── login_viewmodel_test.dart
        ├── signup_viewmodel_test.dart
        └── email_verification_viewmodel_test.dart
```

### Key Files Reference

| File | Purpose | Lines |
|------|---------|-------|
| `password_hash_service.dart` | PBKDF2 hashing implementation | 279 |
| `login_viewmodel.dart` | Login authentication logic | 104 |
| `signup_viewmodel.dart` | Registration logic | 212 |
| `email_verification_viewmodel.dart` | Verification logic with timer | 246 |
| `auth_choice_screen.dart` | Login/Register entry point | 124 |
| `login_screen.dart` | Login UI | 235 |
| `signup_screen.dart` | Registration UI | 393 |
| `email_verification_screen.dart` | Verification UI | 321 |
| `settings_viewmodel.dart` | User state + logout | 163 |
| `splash_screen.dart` | App startup navigation | 98 |

---

## Future Enhancements (Phase 2 & 3)

### Phase 2: Backend Integration

- [ ] Backend API for user registration/login
- [ ] JWT token-based authentication
- [ ] Secure token storage (flutter_secure_storage)
- [ ] Token refresh mechanism
- [ ] Email sending service (real verification emails)
- [ ] Password reset flow
- [ ] Rate limiting for verification codes
- [ ] Biometric authentication (fingerprint, face ID)

### Phase 3: Advanced Features

- [ ] OAuth integration (Google, Apple)
- [ ] Two-factor authentication (2FA)
- [ ] Social login (Facebook, etc.)
- [ ] Account recovery
- [ ] Device management
- [ ] Session management across devices

---

## References

- **AUTH_PLAN.md**: Complete authentication planning document
- **README.md**: Project overview and setup
- **PBKDF2 Documentation**: [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html)
- **Flutter Security**: [Flutter Security Best Practices](https://flutter.dev/docs/development/data-and-backend/security)

---

**Document Version**: 1.0
**Last Updated**: 2025-12-29
**Status**: FR-1 & FR-2 Complete (Phase 1 MVP)
