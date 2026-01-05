import 'package:flutter/material.dart';
import 'package:sleepbalance/features/settings/presentation/screens/date_time_screen.dart';
import 'package:sleepbalance/features/settings/presentation/screens/settings_screen.dart';
import 'package:sleepbalance/features/settings/presentation/screens/timezone_screen.dart';
import 'package:sleepbalance/features/settings/presentation/screens/units_screen.dart';
import 'package:sleepbalance/features/settings/presentation/screens/userprofile_screen.dart';

class SettingsNavigator extends StatelessWidget {
  const SettingsNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      // optional: for state restoration across app restarts
      // restorationScopeId: 'settings-nav',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          case '/timezone':
            return MaterialPageRoute(builder: (_) => const TimezoneScreen());
          case '/units':
            return MaterialPageRoute(builder: (_) => const UnitsScreen());
          case '/format':
            return MaterialPageRoute(builder: (_) => const DateTimeScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const UserProfileScreen());
          default:
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
        }
      },
    );
  }
}
