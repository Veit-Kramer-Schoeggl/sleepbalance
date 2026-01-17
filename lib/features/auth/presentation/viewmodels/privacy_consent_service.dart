import 'package:shared_preferences/shared_preferences.dart';

/// PrivacyConsentService
/// A small persistence service responsible for storing and retrieving
/// the user's data privacy consent decision.
/// This service uses `SharedPreferences` to persist the consent flag
/// locally on the device.

class PrivacyConsentService {
  static const String _key = 'privacy_accepted_v1';

  Future<bool> hasAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  Future<void> resetForDebug() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
