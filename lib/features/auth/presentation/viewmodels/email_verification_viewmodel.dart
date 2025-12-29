import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/email_verification.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/email_verification_repository.dart';

/// Email Verification ViewModel
///
/// Manages state and business logic for email verification flow.
/// Extends ChangeNotifier to enable reactive UI updates via Provider.
///
/// Responsibilities:
/// - Verify email verification codes
/// - Manage countdown timer for code expiration
/// - Handle code resend functionality
/// - Mark email as verified after successful verification
/// - Manage loading and error states
/// - Notify UI of state changes
class EmailVerificationViewModel extends ChangeNotifier {
  final String email;
  final EmailVerificationRepository _emailVerificationRepository;
  final AuthRepository _authRepository;

  EmailVerificationViewModel({
    required this.email,
    required EmailVerificationRepository emailVerificationRepository,
    required AuthRepository authRepository,
  })  : _emailVerificationRepository = emailVerificationRepository,
        _authRepository = authRepository;

  // State
  bool _isLoading = false;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  EmailVerification? _activeVerification;
  Timer? _expirationTimer;
  int _secondsRemaining = 0;

  // Getters - expose state to UI
  bool get isLoading => _isLoading;
  bool get isVerifying => _isVerifying;
  bool get isResending => _isResending;
  String? get errorMessage => _errorMessage;
  int get secondsRemaining => _secondsRemaining;
  int get minutesRemaining => _secondsRemaining ~/ 60;
  int get secondsRemainingInMinute => _secondsRemaining % 60;
  bool get hasExpired => _secondsRemaining <= 0;

  /// Loads the active verification for this email
  ///
  /// Should be called in initState of EmailVerificationScreen.
  /// Starts the countdown timer if verification exists.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   viewModel.loadActiveVerification();
  /// }
  /// ```
  Future<void> loadActiveVerification() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _activeVerification = await _emailVerificationRepository.getActiveVerification(email);

      if (_activeVerification != null) {
        _startExpirationTimer();
      } else {
        _errorMessage = 'No active verification found. Please request a new code.';
      }
    } catch (e) {
      _errorMessage = 'Failed to load verification: $e';
      debugPrint('EmailVerificationViewModel: Error loading verification: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifies the entered code
  ///
  /// Process:
  /// 1. Validates code format (6 digits)
  /// 2. Verifies code against repository
  /// 3. Marks email as verified in user record
  /// 4. Stops countdown timer
  ///
  /// Parameters:
  /// - [code]: The 6-digit verification code entered by user
  ///
  /// Returns true if verification successful, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final success = await viewModel.verifyCode('123456');
  /// if (success) {
  ///   // Navigate to main screen
  /// } else {
  ///   // Show error: viewModel.errorMessage
  /// }
  /// ```
  Future<bool> verifyCode(String code) async {
    try {
      _isVerifying = true;
      _errorMessage = null;
      notifyListeners();

      // Validate code format
      if (code.length != 6 || int.tryParse(code) == null) {
        _errorMessage = 'Please enter a valid 6-digit code';
        return false;
      }

      // Verify code
      final isValid = await _emailVerificationRepository.verifyCode(email, code);

      if (!isValid) {
        _errorMessage = 'Invalid or expired verification code';
        return false;
      }

      // Mark email as verified
      await _authRepository.markEmailVerified(email);

      // Stop timer
      _stopExpirationTimer();

      debugPrint('EmailVerificationViewModel: Email verified successfully: $email');

      return true;
    } catch (e) {
      _errorMessage = 'Verification failed. Please try again.';
      debugPrint('EmailVerificationViewModel: Error verifying code: $e');
      return false;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  /// Resends a new verification code
  ///
  /// Generates a new code and restarts the countdown timer.
  /// Invalidates the previous code.
  ///
  /// Returns true if successful, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final success = await viewModel.resendCode();
  /// if (success) {
  ///   // Show success message
  /// }
  /// ```
  Future<bool> resendCode() async {
    try {
      _isResending = true;
      _errorMessage = null;
      notifyListeners();

      // Create new verification code
      final code = await _emailVerificationRepository.createVerificationCode(email);

      debugPrint('EmailVerificationViewModel: New verification code: $code (for test mode)');

      // Reload active verification to get new expiration
      await loadActiveVerification();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to resend code. Please try again.';
      debugPrint('EmailVerificationViewModel: Error resending code: $e');
      return false;
    } finally {
      _isResending = false;
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

  // Private methods

  /// Starts the countdown timer for code expiration
  void _startExpirationTimer() {
    _stopExpirationTimer(); // Stop existing timer if any

    if (_activeVerification == null) return;

    _updateSecondsRemaining();

    _expirationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateSecondsRemaining();

      if (_secondsRemaining <= 0) {
        _stopExpirationTimer();
        _errorMessage = 'Verification code has expired. Please request a new one.';
        notifyListeners();
      } else {
        notifyListeners();
      }
    });
  }

  /// Updates seconds remaining based on current time
  void _updateSecondsRemaining() {
    if (_activeVerification == null) {
      _secondsRemaining = 0;
      return;
    }

    final now = DateTime.now();
    final remaining = _activeVerification!.expiresAt.difference(now);

    _secondsRemaining = remaining.inSeconds > 0 ? remaining.inSeconds : 0;
  }

  /// Stops the countdown timer
  void _stopExpirationTimer() {
    _expirationTimer?.cancel();
    _expirationTimer = null;
  }

  @override
  void dispose() {
    _stopExpirationTimer();
    super.dispose();
  }
}
