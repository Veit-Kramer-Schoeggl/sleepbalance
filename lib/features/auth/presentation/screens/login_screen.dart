import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/onboarding/presentation/screens/questionnaire_screen.dart';
import '../../../../shared/services/storage/preferences_service.dart';
import '../../../../shared/widgets/navigation/main_navigation.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../settings/domain/repositories/user_repository.dart';
import '../viewmodels/login_viewmodel.dart';

/// Login Screen
///
/// User login form with:
/// - Email (validated)
/// - Password (with visibility toggle)
///
/// On successful login:
/// - First time users → navigates to QuestionnaireScreen
/// - Returning users → navigates to MainNavigation
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles form submission and user login
  Future<void> _handleLogin(LoginViewModel viewModel) async {
    // Clear previous errors
    viewModel.clearError();

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    final success = await viewModel.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // Check if first launch to determine navigation destination
      final isFirstLaunch = await PreferencesService.isFirstLaunch();
      if (!mounted) return;

      if (isFirstLaunch) {
        // First time user - go to questionnaire
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
          (route) => false,
        );
      } else {
        // Returning user - go to main app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false,
        );
      }
    } else {
      // Error message already set in viewModel - show in SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Create LoginViewModel locally (not from global Provider)
      create: (_) => LoginViewModel(
        userRepository: context.read<UserRepository>(),
      ),
      child: BackgroundWrapper(
        imagePath: 'assets/images/main_background.png',
        overlayOpacity: 0.3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Login', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Consumer<LoginViewModel>(
            builder: (context, viewModel, _) {
              return Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome back',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Login to your account',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email, color: Colors.white70),
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
                          prefixIcon: const Icon(Icons.lock, color: Colors.white70),
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
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Error Message Display
                      if (viewModel.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  viewModel.errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Login Button
                      ElevatedButton(
                        onPressed: viewModel.isLoading
                            ? null
                            : () => _handleLogin(viewModel),
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
                                'Login',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
