import 'package:flutter/cupertino.dart';

class SettingsViewModel extends ChangeNotifier {
  final BuildContext _context;

  SettingsViewModel({
    required BuildContext context,
  }) : _context = context;

  void onChangeTimeZone() {
    Navigator.of(_context).pushNamed('/timezone');
  }

  void onChangeUserProfile() {
    Navigator.of(_context).pushNamed('/profile');
  }

  void onChangeDateTimeFormat() {
    Navigator.of(_context).pushNamed('/format');
  }

  void onChangeUnits() {
    Navigator.of(_context).pushNamed('/units');
  }
}