import 'package:flutter/material.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/acceptance_button.dart';

/// Habits Lab screen for sleep habit tracking and experimentation
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Habits Lab', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Habits Lab',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Track and experiment with sleep habits',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AcceptanceButton(
                text: 'Save Habits',
                onPressed: () {
                  // Handle save action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Habits saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
