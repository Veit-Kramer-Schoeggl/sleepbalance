import 'package:flutter/material.dart';
import 'shared/screens/app/splash_screen.dart';
import 'fitbit_test.dart';

void main() {
  runApp(const SleepBalanceApp());
}

class SleepBalanceApp extends StatelessWidget {
  const SleepBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SleepBalance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/fitbit': (context) => const FitbitTest(),
      }

    );
  }
}
