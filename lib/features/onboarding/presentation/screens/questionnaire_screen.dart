import 'package:flutter/material.dart';
import '../../../../shared/services/storage/preferences_service.dart';
import '../../../../shared/widgets/navigation/main_navigation.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';

class QuestionnaireScreen extends StatelessWidget {
  const QuestionnaireScreen({super.key});

  Future<void> _completeSetup(BuildContext context) async {
    await PreferencesService.setFirstLaunchComplete();
    if (context.mounted) {
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
        appBar: AppBar(
          title: const Text('Setup'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Questionnaire',
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Initial setup will go here',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => _completeSetup(context),
                child: const Text('Complete Setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}