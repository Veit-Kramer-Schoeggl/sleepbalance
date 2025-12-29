import 'package:flutter/foundation.dart';

import '../../../settings/domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/email_verification_repository.dart';
import '../../domain/validators/password_validator.dart';

/// Signup ViewModel
///
/// Manages state and business logic for user registration flow.
/// Extends ChangeNotifier to enable reactive UI updates via Provider.
///
/// Responsibilities:
/// - Handle user registration
/// - Validate password and calculate strength
/// - Create email verification code
/// - Manage loading and error states
/// - Notify UI of state changes
class SignupViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final EmailVerificationRepository _emailVerificationRepository;

  SignupViewModel({
    required AuthRepository authRepository,
    required EmailVerificationRepository emailVerificationRepository,
  })  : _authRepository = authRepository,
        _emailVerificationRepository = emailVerificationRepository;

  // State
  bool _isLoading = false;
  String? _errorMessage;
  User? _createdUser;
  String? _verificationCode; // For test mode display

  // Getters - expose state to UI
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get createdUser => _createdUser;
  String? get verificationCode => _verificationCode;

  /// Validates password and returns detailed validation result
  ///
  /// Used for real-time validation feedback in UI.
  /// Does not trigger state changes.
  ///
  /// Example:
  /// ```dart
  /// final result = viewModel.validatePassword('MyPass123');
  /// if (!result.isValid) {
  ///   // Show errors: result.errors
  /// }
  /// ```
  PasswordValidationResult validatePassword(String password) {
    return PasswordValidator.validate(password);
  }

  /// Calculates password strength for real-time UI feedback
  ///
  /// Returns weak/medium/strong strength level.
  /// Used to show strength indicator while user types.
  ///
  /// Example:
  /// ```dart
  /// final strength = viewModel.calculatePasswordStrength('MyPass123');
  /// // Returns PasswordStrength.strong
  /// ```
  PasswordStrength calculatePasswordStrength(String password) {
    return PasswordValidator.calculateStrength(password);
  }

  /// Registers a new user with email verification
  ///
  /// Process:
  /// 1. Validates all inputs
  /// 2. Checks if email already exists
  /// 3. Creates user account with hashed password
  /// 4. Generates 6-digit verification code
  /// 5. Stores created user and code in state
  ///
  /// Parameters:
  /// - [email]: User's email address
  /// - [password]: Plain text password (will be hashed)
  /// - [firstName]: User's first name
  /// - [lastName]: User's last name
  /// - [birthDate]: User's date of birth
  /// - [timezone]: IANA timezone ID from device
  ///
  /// Returns true if successful, false otherwise.
  /// Sets errorMessage on failure.
  ///
  /// Example:
  /// ```dart
  /// final success = await viewModel.signupUser(
  ///   email: 'user@example.com',
  ///   password: 'SecurePass123',
  ///   firstName: 'John',
  ///   lastName: 'Doe',
  ///   birthDate: DateTime(1990, 1, 1),
  ///   timezone: 'America/Los_Angeles',
  /// );
  /// if (success) {
  ///   // Navigate to email verification screen
  ///   // Pass viewModel.createdUser.email and viewModel.verificationCode
  /// }
  /// ```
  Future<bool> signupUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String timezone,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _createdUser = null;
      _verificationCode = null;
      notifyListeners();

      // Validate password
      final passwordValidation = PasswordValidator.validate(password);
      if (!passwordValidation.isValid) {
        _errorMessage = 'Password does not meet requirements:\n${passwordValidation.errors.join('\n')}';
        return false;
      }

      // Register user
      final user = await _authRepository.registerUser(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        timezone: timezone,
      );

      // Create verification code
      final code = await _emailVerificationRepository.createVerificationCode(email);

      // Store for navigation and test mode display
      _createdUser = user;
      _verificationCode = code;

      debugPrint('SignupViewModel: User registered successfully: ${user.email}');
      debugPrint('SignupViewModel: Verification code: $code (for test mode)');

      return true;
    } on EmailAlreadyExistsException catch (e) {
      _errorMessage = e.message;
      debugPrint('SignupViewModel: Email already exists: $e');
      return false;
    } on AuthException catch (e) {
      _errorMessage = 'Registration failed: ${e.message}';
      debugPrint('SignupViewModel: Auth error: $e');
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      debugPrint('SignupViewModel: Unexpected error during signup: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears any error message
  ///
  /// Useful for dismissing error banners in UI.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Resets all state
  ///
  /// Useful when navigating away from signup screen.
  void reset() {
    _isLoading = false;
    _errorMessage = null;
    _createdUser = null;
    _verificationCode = null;
    notifyListeners();
  }
}
