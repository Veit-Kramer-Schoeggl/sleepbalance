import 'package:flutter/foundation.dart';
import '../../../settings/domain/models/user.dart';
import '../../../settings/domain/repositories/user_repository.dart';
import '../../data/services/password_hash_service.dart';

/// ViewModel for user login functionality
///
/// Handles email + password authentication with local password verification.
/// Uses PBKDF2-HMAC-SHA256 for password hash verification.
/// Requires email verification before allowing login.
class LoginViewModel extends ChangeNotifier {
  final UserRepository _userRepository;

  LoginViewModel({required UserRepository userRepository})
      : _userRepository = userRepository;

  bool _isLoading = false;
  String? _errorMessage;
  User? _authenticatedUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get authenticatedUser => _authenticatedUser;

  /// Authenticates user with email and password
  ///
  /// Returns true if login successful, false otherwise.
  /// Sets [errorMessage] on failure.
  ///
  /// Validation steps:
  /// 1. Check inputs are not empty
  /// 2. Look up user by email
  /// 3. Verify password hash (PBKDF2)
  /// 4. Check email verification status
  /// 5. Set as current user in SharedPreferences
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _authenticatedUser = null;
      notifyListeners();

      // Validate inputs
      if (email.trim().isEmpty || password.isEmpty) {
        _errorMessage = 'Please enter both email and password';
        return false;
      }

      // Look up user by email
      final user = await _userRepository.getUserByEmail(email.trim());
      if (user == null) {
        _errorMessage = 'No account found with this email address';
        return false;
      }

      // Verify password hash
      if (user.passwordHash == null) {
        _errorMessage = 'Account is not set up correctly';
        return false;
      }

      final passwordValid = await PasswordHashService.verifyPassword(
        password,
        user.passwordHash!,
      );
      if (!passwordValid) {
        _errorMessage = 'Incorrect password';
        return false;
      }

      // Check email verification
      if (!user.emailVerified) {
        _errorMessage = 'Please verify your email address before logging in';
        return false;
      }

      // Set as current user
      await _userRepository.setCurrentUserId(user.id);
      _authenticatedUser = user;

      debugPrint('LoginViewModel: User logged in successfully: ${user.email}');
      return true;
    } catch (e) {
      _errorMessage = 'Login failed. Please try again.';
      debugPrint('LoginViewModel: Error during login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the current error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
