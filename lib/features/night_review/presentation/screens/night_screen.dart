import 'package:flutter/material.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';

/// Night Review screen for reviewing previous night's sleep data
class NightScreen extends StatelessWidget {
  const NightScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Night Review'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bedtime,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Night Review',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8),
              Text(
                'Review your previous night\'s sleep',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
