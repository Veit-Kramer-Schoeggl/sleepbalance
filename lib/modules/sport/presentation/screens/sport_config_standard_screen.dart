import 'package:flutter/material.dart';

class SportConfigStandardScreen extends StatelessWidget {
  const SportConfigStandardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Physical Activity'),
          centerTitle: true,),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'This module is a prototype.\n\n'
              'Future versions will include activity timing and intensity recommendations.',
        ),
      ),
    );
  }
}
