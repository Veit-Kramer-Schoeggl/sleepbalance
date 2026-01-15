import 'package:flutter/material.dart';

import '../../../../shared/widgets/ui/background_wrapper.dart';

class TimezoneScreen extends StatelessWidget {
  const TimezoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
        imagePath: 'assets/images/main_background.png',
        overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Timezone Settings', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Timezone Settings',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
            ],
          ),
        )
      )
    );
  }
}
