import 'package:flutter/material.dart';
import '../../../features/onboarding/presentation/screens/questionnaire_screen.dart';
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
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    // Add a small delay to show the splash briefly
    await Future.delayed(const Duration(milliseconds: 500));

    final isFirstLaunch = await PreferencesService.isFirstLaunch();

    if (mounted) {
      if (isFirstLaunch) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const QuestionnaireScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
      }
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