/// Wearable device provider types
///
/// Represents different wearable device platforms that can be connected
/// to sync sleep and health data.
enum WearableProvider {
  /// Fitbit devices (Charge, Versa, Sense, etc.)
  fitbit,

  /// Apple Health (via HealthKit on iOS)
  appleHealth,

  /// Google Fit (Android)
  googleFit,

  /// Garmin devices
  garmin;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case WearableProvider.fitbit:
        return 'Fitbit';
      case WearableProvider.appleHealth:
        return 'Apple Health';
      case WearableProvider.googleFit:
        return 'Google Fit';
      case WearableProvider.garmin:
        return 'Garmin';
    }
  }

  /// API identifier for database storage
  ///
  /// Lowercase string representation used in database provider column.
  /// Must match CHECK constraint in wearable_connections table.
  String get apiIdentifier {
    switch (this) {
      case WearableProvider.fitbit:
        return 'fitbit';
      case WearableProvider.appleHealth:
        return 'apple_health';
      case WearableProvider.googleFit:
        return 'google_fit';
      case WearableProvider.garmin:
        return 'garmin';
    }
  }

  /// Parse from database string
  ///
  /// Converts database provider value back to enum.
  /// Throws ArgumentError if provider string is invalid.
  static WearableProvider fromString(String value) {
    switch (value) {
      case 'fitbit':
        return WearableProvider.fitbit;
      case 'apple_health':
        return WearableProvider.appleHealth;
      case 'google_fit':
        return WearableProvider.googleFit;
      case 'garmin':
        return WearableProvider.garmin;
      default:
        throw ArgumentError('Invalid wearable provider: $value');
    }
  }
}
