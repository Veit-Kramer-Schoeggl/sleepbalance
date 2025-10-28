import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SleepBalance'),
      ),
      body: const Center(
        child: Text(
          'Sleep Dashboard',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}