import 'package:flutter/material.dart';

class MeditationConfigStandardScreen extends StatelessWidget {
  const MeditationConfigStandardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Meditation & Relaxation'),
          centerTitle: true,
          ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
            'This module is a prototype.\n\n'
                'Future versions will include guided meditation and relaxation features.',
        ),
      ),
    );
  }
}
