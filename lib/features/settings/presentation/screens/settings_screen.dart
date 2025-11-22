import 'package:flutter/material.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';

/// Settings Screen - Main settings overview
///
/// Uses the global SettingsViewModel from main.dart Provider tree.
/// Navigation is handled locally within this screen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('App Settings', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.settings,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure your app preferences',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/timezone'),
                      label: const Text("Timezone"),
                      icon: const Icon(Icons.access_time),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/profile'),
                      label: const Text("Userprofile"),
                      icon: const Icon(Icons.person),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/format'),
                      label: const Text("Date/Time Format"),
                      icon: const Icon(Icons.date_range),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed('/units'),
                      label: const Text("Units (Imperial/Metric)"),
                      icon: const Icon(Icons.straighten),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}