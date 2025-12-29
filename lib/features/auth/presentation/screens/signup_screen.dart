import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../domain/validators/password_validator.dart';
import '../viewmodels/signup_viewmodel.dart';
import '../widgets/password_strength_indicator.dart';
import 'email_verification_screen.dart';

/// Signup Screen
///
/// User registration form with:
/// - First Name, Last Name (required)
/// - Email (validated)
/// - Password (with strength indicator and requirements list)
/// - Birth Date (date picker)
/// - Timezone (auto-detected, display-only)
///
/// On successful registration, navigates to EmailVerificationScreen.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  DateTime? _selectedBirthDate;
  String _timezone = 'UTC';
  bool _obscurePassword = true;
  PasswordStrength _passwordStrength = PasswordStrength.weak;
  PasswordValidationResult? _passwordValidation;

  @override
  void initState() {
    super.initState();
    _detectTimezone();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Detects device timezone using flutter_timezone package
  Future<void> _detectTimezone() async {
    try {
      _timezone = await FlutterTimezone.getLocalTimezone();
      // Returns IANA timezone ID like "America/Los_Angeles", "Europe/Berlin", etc.
    } catch (e) {
      // Fallback to UTC if detection fails
      _timezone = 'UTC';
      debugPrint('Failed to detect timezone: $e');
    }
    if (mounted) {
      setState(() {});
    }
  }

  /// Updates password strength indicator in real-time
  void _onPasswordChanged() {
    final viewModel = context.read<SignupViewModel>();
    setState(() {
      _passwordStrength = viewModel.calculatePasswordStrength(_passwordController.text);
      _passwordValidation = viewModel.validatePassword(_passwordController.text);
    });
  }

  /// Builds date picker input field
  Widget _datePicker(BuildContext context) {
    final formatted = _selectedBirthDate == null
        ? 'Please select'
        : DateFormat('dd.MM.yyyy').format(_selectedBirthDate!);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final initialDate = _selectedBirthDate ??
            DateTime(now.year - 20, now.month, now.day);

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1900),
          lastDate: now,
        );

        if (picked != null) {
          setState(() {
            _selectedBirthDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Birth Date',
          labelStyle: TextStyle(color: Colors.white),
          hintText: 'DD.MM.YYYY',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today, color: Colors.white),
        ),
        child: Text(formatted, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Builds password requirements list
  Widget _buildPasswordRequirements() {
    if (_passwordValidation == null || _passwordController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Password Requirements:',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        _buildRequirementItem('At least 8 characters', _passwordValidation!.hasMinimumLength),
        _buildRequirementItem('One uppercase letter', _passwordValidation!.hasUppercase),
        _buildRequirementItem('One lowercase letter', _passwordValidation!.hasLowercase),
        _buildRequirementItem('One number', _passwordValidation!.hasNumber),
      ],
    );
  }

  /// Builds individual requirement item with checkmark
  Widget _buildRequirementItem(String text, bool satisfied) {
    return Row(
      children: [
        Icon(
          satisfied ? Icons.check_circle : Icons.cancel,
          color: satisfied ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: satisfied ? Colors.white : Colors.white54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Handles form submission and user registration
  Future<void> _handleSignup() async {
    // Clear previous errors
    context.read<SignupViewModel>().clearError();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate birth date
    if (_selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birth date')),
      );
      return;
    }

    _formKey.currentState!.save();

    final viewModel = context.read<SignupViewModel>();
    final success = await viewModel.signupUser(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      birthDate: _selectedBirthDate!,
      timezone: _timezone,
    );

    if (!mounted) return;

    if (success) {
      // Navigate to email verification screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: viewModel.createdUser!.email,
            displayCode: viewModel.verificationCode, // For test mode
          ),
        ),
      );
    } else {
      // Error message already set in viewModel
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(viewModel.errorMessage ?? 'Signup failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Sign Up', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Consumer<SignupViewModel>(
          builder: (context, viewModel, _) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create your account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // First Name
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'First name is required'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Last Name
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Last name is required'
                              : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Invalid email address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white),
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        final validation = viewModel.validatePassword(value);
                        return validation.isValid ? null : 'Password does not meet requirements';
                      },
                    ),
                    const SizedBox(height: 8),

                    // Password Strength Indicator
                    if (_passwordController.text.isNotEmpty)
                      PasswordStrengthIndicator(strength: _passwordStrength),

                    // Password Requirements List
                    _buildPasswordRequirements(),
                    const SizedBox(height: 16),

                    // Birth Date
                    _datePicker(context),
                    const SizedBox(height: 16),

                    // Timezone (display-only)
                    TextFormField(
                      initialValue: _timezone,
                      decoration: const InputDecoration(
                        labelText: 'Timezone',
                        labelStyle: TextStyle(color: Colors.white),
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.lock, color: Colors.white54),
                      ),
                      enabled: false,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),

                    // Sign Up Button
                    ElevatedButton(
                      onPressed: viewModel.isLoading ? null : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
