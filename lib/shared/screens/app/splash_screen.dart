import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/auth/presentation/screens/auth_choice_screen.dart';
import '../../../features/onboarding/presentation/screens/questionnaire_screen.dart';
import '../../../features/settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../services/storage/preferences_service.dart';
import '../../widgets/navigation/main_navigation.dart';
import '../../widgets/ui/background_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to ensure widget tree is fully built
    // before accessing context and calling Provider methods
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
  }

  Future<void> _checkFirstLaunch() async {
    // Get SettingsViewModel from Provider
    final settingsViewModel = context.read<SettingsViewModel>();

    // Load current user FIRST - this ensures user data is available
    // immediately when the app opens
    await settingsViewModel.loadCurrentUser();

    // Add a delay to show the splash screen briefly (improve UX)
    await Future.delayed(const Duration(seconds: 2));

    // Check if widget is still mounted before navigation
    if (!mounted) return;

    // Get current user
    final user = settingsViewModel.currentUser;

    // Check if user exists and email is verified
    if (user == null || !user.emailVerified) {
      // Navigate to auth choice screen (user doesn't exist or email not verified)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AuthChoiceScreen()),
      );
      return;
    }

    // Check if this is the first launch for questionnaire
    // Uses PreferencesService which respects the forceOnboarding debug flag
    final isFirstLaunch = await PreferencesService.isFirstLaunch();

    if (!mounted) return;

    if (isFirstLaunch) {
      // Navigate to onboarding questionnaire
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const QuestionnaireScreen()),
      );
    } else {
      // Navigate to main app (user already loaded and verified)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
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
        body: Center(
          child: Image.asset(
            'assets/images/moon_star.png',
            width: 120,
            height: 120,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to icon if image not found
              return const Icon(
                Icons.nightlight_round,
                size: 120,
                color: Colors.white,
              );
            },
          ),
        ),
      ),
    );
  }
}