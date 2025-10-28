import 'package:flutter/material.dart';
import '../../../shared/services/preferences_service.dart';
import '../../dashboard/presentation/dashboard_screen.dart';

class QuestionnaireScreen extends StatelessWidget {
  const QuestionnaireScreen({super.key});

  Future<void> _completeSetup(BuildContext context) async {
    await PreferencesService.setFirstLaunchComplete();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Questionnaire',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            const Text(
              'Initial setup will go here',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _completeSetup(context),
              child: const Text('Complete Setup'),
            ),
          ],
        ),
      ),
    );
  }
}