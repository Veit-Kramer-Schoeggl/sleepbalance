import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/action_center/presentation/viewmodels/database_management_viewmodel.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

/// Authentication Choice Screen
///
/// Landing screen for unauthenticated users.
/// Presents two options:
/// - Login to existing account
/// - Create new account
///
/// This screen replaces SignupScreen as the default destination
/// when no user is logged in.
///
/// Also includes database management tools (dev mode only) for easy
/// seeding and clearing during development.
class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DatabaseManagementViewModel(),
      child: const _AuthChoiceContent(),
    );
  }
}

class _AuthChoiceContent extends StatelessWidget {
  const _AuthChoiceContent();

  Future<void> _handleSeedDatabase(BuildContext context) async {
    final dbViewModel = context.read<DatabaseManagementViewModel>();

    await dbViewModel.seedDatabase();

    if (!context.mounted) return;

    if (dbViewModel.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dbViewModel.successMessage!),
          backgroundColor: Colors.green,
        ),
      );
    } else if (dbViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dbViewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleClearDatabase(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Database?'),
        content: const Text(
          'This will delete ALL data. This action cannot be undone.\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All Data'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final dbViewModel = context.read<DatabaseManagementViewModel>();
    await dbViewModel.clearDatabase();

    if (!context.mounted) return;

    if (dbViewModel.successMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dbViewModel.successMessage!),
          backgroundColor: Colors.green,
        ),
      );
    } else if (dbViewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dbViewModel.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbViewModel = context.watch<DatabaseManagementViewModel>();

    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Spacer to push content to center
                const Spacer(),

                // App Logo/Icon
                Icon(
                  Icons.bedtime,
                  size: 80,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 24),

                // App Name
                const Text(
                  'SleepBalance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),

                // Tagline
                Text(
                  'Your personal sleep companion',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 64),

                // Login Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),

                // Create Account Button
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignupScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Colors.white, width: 2),
                  ),
                  child: const Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Dev Tools section (only in debug mode)
                if (kDebugMode) ...[
                  const SizedBox(height: 32),

                  // Database Management Buttons (Dev Tools)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.construction, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'DEV TOOLS',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: dbViewModel.isSeeding
                                    ? null
                                    : () => _handleSeedDatabase(context),
                                icon: dbViewModel.isSeeding
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.cloud_upload),
                                label: const Text('Seed DB'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: dbViewModel.isClearing
                                    ? null
                                    : () => _handleClearDatabase(context),
                                icon: dbViewModel.isClearing
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.delete_forever),
                                label: const Text('Clear DB'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Spacer to push content to center
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
