import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _firstLaunchKey = 'is_first_launch';
  
  // Debug flag - set to true to force questionnaire
  static const bool FORCE_ONBOARDING = true;
  
  static Future<bool> isFirstLaunch() async {
    // Force questionnaire if debug flag is true
    if (FORCE_ONBOARDING) return true;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? true;
  }
  
  static Future<void> setFirstLaunchComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, false);
  }
}