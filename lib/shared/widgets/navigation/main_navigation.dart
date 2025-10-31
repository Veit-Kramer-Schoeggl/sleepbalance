import 'package:flutter/material.dart';
import 'package:sleepbalance/features/night_review/presentation/screens/night_screen.dart';
import 'package:sleepbalance/features/habits_lab/presentation/screens/habits_screen.dart';
import 'package:sleepbalance/features/action_center/presentation/screens/action_screen.dart';
import 'package:sleepbalance/features/settings/presentation/settings_navigator.dart';

/// Main navigation wrapper with bottom navigation bar
/// Uses IndexedStack to preserve state across tab switches
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 2; // Default to Action tab (index 2)

  // List of screens corresponding to navigation items
  final List<Widget> _screens = const [
    SettingsNavigator(),
    NightScreen(),
    ActionScreen(),
    HabitsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bedtime),
            label: 'Night',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt),
            label: 'Action',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Habits',
          ),
        ],
      ),
    );
  }
}
