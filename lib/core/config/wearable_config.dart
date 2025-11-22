import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for wearable provider OAuth credentials
///
/// Loads credentials from environment variables (.env file).
/// Call [WearableConfig.load()] in main() before using.
///
/// Usage:
/// ```dart
/// // In main.dart
/// await WearableConfig.load();
///
/// // Anywhere in app
/// final clientId = WearableConfig.fitbitClientId;
/// ```
class WearableConfig {
  WearableConfig._();

  /// Load environment variables from .env file
  ///
  /// Must be called before accessing any config values.
  /// Typically called in main() before runApp().
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  // ==========================================================================
  // Fitbit Configuration
  // ==========================================================================

  /// Fitbit OAuth Client ID
  static String get fitbitClientId =>
      dotenv.env['FITBIT_CLIENT_ID'] ?? '';

  /// Fitbit OAuth Client Secret
  static String get fitbitClientSecret =>
      dotenv.env['FITBIT_CLIENT_SECRET'] ?? '';

  /// Fitbit OAuth Redirect URI (deep link)
  static const String fitbitRedirectUri = 'sleepbalance://fitbit-auth';

  /// Fitbit callback URL scheme for deep linking
  static const String fitbitCallbackScheme = 'sleepbalance';

  /// Check if Fitbit credentials are configured
  static bool get isFitbitConfigured =>
      fitbitClientId.isNotEmpty && fitbitClientSecret.isNotEmpty;

  // ==========================================================================
  // Future Providers (uncomment when implementing)
  // ==========================================================================

  // /// Garmin OAuth Client ID
  // static String get garminClientId =>
  //     dotenv.env['GARMIN_CLIENT_ID'] ?? '';

  // /// Garmin OAuth Client Secret
  // static String get garminClientSecret =>
  //     dotenv.env['GARMIN_CLIENT_SECRET'] ?? '';

  // /// Google Fit OAuth Client ID
  // static String get googleFitClientId =>
  //     dotenv.env['GOOGLE_FIT_CLIENT_ID'] ?? '';

  // /// Google Fit OAuth Client Secret
  // static String get googleFitClientSecret =>
  //     dotenv.env['GOOGLE_FIT_CLIENT_SECRET'] ?? '';
}
