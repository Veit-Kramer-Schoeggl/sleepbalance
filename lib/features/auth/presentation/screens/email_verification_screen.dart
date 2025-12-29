import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/onboarding/presentation/screens/questionnaire_screen.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../settings/domain/repositories/user_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/email_verification_repository.dart';
import '../viewmodels/email_verification_viewmodel.dart';
import '../widgets/verification_code_input.dart';

/// Email Verification Screen
///
/// Allows users to verify their email address using a 6-digit code.
///
/// Features:
/// - Displays email being verified
/// - 6-digit code input
/// - Countdown timer (15 minutes)
/// - Verify button
/// - Resend code button
/// - Test mode: displays verification code in amber box
///
/// On successful verification, navigates to MainNavigation.
class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final String? displayCode; // For test mode only

  const EmailVerificationScreen({
    super.key,
    required this.email,
    this.displayCode,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _codeController = TextEditingController();
  late EmailVerificationViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    // Create ViewModel with email parameter
    final authRepository = context.read<AuthRepository>();
    final verificationRepository = context.read<EmailVerificationRepository>();
    final userRepository = context.read<UserRepository>();

    _viewModel = EmailVerificationViewModel(
      email: widget.email,
      authRepository: authRepository,
      emailVerificationRepository: verificationRepository,
      userRepository: userRepository,
    );

    // Load active verification and start timer
    _viewModel.loadActiveVerification();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  /// Handles code verification
  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    final success = await _viewModel.verifyCode(code);

    if (!mounted) return;

    if (success) {
      // Navigate to questionnaire (clear all previous routes)
      // First-time users always see questionnaire after email verification
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
        (route) => false,
      );
    } else {
      // Error message already set in viewModel
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage ?? 'Verification failed')),
      );
    }
  }

  /// Handles code resend
  Future<void> _handleResend() async {
    final success = await _viewModel.resendCode();

    if (!mounted) return;

    if (success) {
      _codeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New verification code sent!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.errorMessage ?? 'Failed to resend code')),
      );
    }
  }

  /// Formats countdown timer display
  String _formatTimer(int minutes, int seconds) {
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Verify Email', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Verification Icon
                  const Icon(
                    Icons.email,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email display
                  Text(
                    'We sent a verification code to:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Test mode: Display code
                  if (widget.displayCode != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        border: Border.all(color: Colors.amber),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'TEST MODE - Verification Code:',
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.displayCode!,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (widget.displayCode != null) const SizedBox(height: 24),

                  // Countdown timer
                  if (!_viewModel.hasExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.timer, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Code expires in: ${_formatTimer(_viewModel.minutesRemaining, _viewModel.secondsRemainingInMinute)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Code input
                  VerificationCodeInput(
                    controller: _codeController,
                    onCompleted: (_) => _handleVerify(),
                  ),
                  const SizedBox(height: 32),

                  // Verify button
                  ElevatedButton(
                    onPressed: _viewModel.isVerifying ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _viewModel.isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Verify Email',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Resend button
                  TextButton(
                    onPressed: _viewModel.isResending ? null : _handleResend,
                    child: _viewModel.isResending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Resend Code',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),

                  // Error message
                  if (_viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _viewModel.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Loading indicator
                  if (_viewModel.isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
