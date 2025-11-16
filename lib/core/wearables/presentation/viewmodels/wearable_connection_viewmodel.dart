import 'package:fitbitter/fitbitter.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/uuid_generator.dart';
import '../../domain/enums/wearable_provider.dart';
import '../../domain/models/wearable_credentials.dart';
import '../../domain/repositories/wearable_auth_repository.dart';
import '../../utils/fitbit_secrets.dart';

/// ViewModel for Wearable Connections screen
///
/// Manages state and business logic for wearable device OAuth connections.
/// Extends ChangeNotifier to enable reactive UI updates via Provider.
///
/// Responsibilities:
/// - Load connections from repository
/// - Handle Fitbit OAuth flow
/// - Map Fitbit credentials to domain model
/// - Manage loading and error states
/// - Notify UI of state changes
class WearableConnectionViewModel extends ChangeNotifier {
  final WearableAuthRepository _repository;
  final String userId;

  WearableConnectionViewModel({
    required WearableAuthRepository repository,
    required this.userId,
  }) : _repository = repository;

  // State
  List<WearableCredentials> _connections = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters - expose state to UI
  List<WearableCredentials> get connections => _connections;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Check if specific provider is connected
  bool isConnected(WearableProvider provider) {
    return _connections.any((c) => c.provider == provider && c.isActive);
  }

  // Get connection for specific provider
  WearableCredentials? getConnection(WearableProvider provider) {
    try {
      return _connections.firstWhere(
        (c) => c.provider == provider && c.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  /// Load all wearable connections for the user
  ///
  /// Sets loading state, fetches from repository, handles errors.
  /// Always calls notifyListeners() to update UI.
  Future<void> loadConnections() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _connections = await _repository.getAllConnections(userId);
    } catch (e) {
      _errorMessage = 'Failed to load connections: $e';
      debugPrint('WearableConnectionViewModel: Error in loadConnections: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Connect to Fitbit via OAuth
  ///
  /// Steps:
  /// 1. Initiates OAuth flow using fitbitter package
  /// 2. User authorizes in browser
  /// 3. Receives FitbitCredentials from OAuth callback
  /// 4. Maps to WearableCredentials domain model
  /// 5. Saves to repository
  /// 6. Reloads connections to update UI
  Future<void> connectFitbit() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Request all available scopes for comprehensive data access
      // Note: FitbitConnector.authorize is a static method
      final fitbitCredentials = await FitbitConnector.authorize(
        clientID: FitbitSecrets.clientId,
        clientSecret: FitbitSecrets.clientSecret,
        redirectUri: FitbitSecrets.redirectUri,
        callbackUrlScheme: FitbitSecrets.callbackScheme,
        scopeList: [
          FitbitAuthScope.ACTIVITY,
          FitbitAuthScope.HEART_RATE,
          FitbitAuthScope.SLEEP,
          FitbitAuthScope.PROFILE,
          FitbitAuthScope.NUTRITION,
          FitbitAuthScope.OXYGEN_SATURATION,
        ],
        expiresIn: 28800, // 8 hours
      );

      if (fitbitCredentials == null) {
        _errorMessage = 'OAuth flow cancelled or failed';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Map FitbitCredentials to WearableCredentials
      // Note: FitbitCredentials only has userID, accessToken, refreshToken
      // expiresIn is calculated from the parameter (28800 seconds = 8 hours)
      final wearableCredentials = WearableCredentials(
        id: UuidGenerator.generate(),
        userId: userId,
        provider: WearableProvider.fitbit,
        accessToken: fitbitCredentials.fitbitAccessToken,
        refreshToken: fitbitCredentials.fitbitRefreshToken,
        tokenExpiresAt: DateTime.now().add(
          const Duration(seconds: 28800), // 8 hours
        ),
        userExternalId: fitbitCredentials.userID,
        grantedScopes: [
          'activity',
          'heartrate',
          'sleep',
          'profile',
          'nutrition',
          'oxygen_saturation',
        ],
        isActive: true,
        connectedAt: DateTime.now(),
        lastSyncAt: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to repository
      await _repository.saveConnection(wearableCredentials);

      // Reload connections to update UI
      await loadConnections();
    } catch (e) {
      _errorMessage = 'Failed to connect Fitbit: $e';
      debugPrint('WearableConnectionViewModel: Error in connectFitbit: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Disconnect from a wearable provider
  ///
  /// Deletes the connection from repository and updates UI.
  Future<void> disconnectProvider(WearableProvider provider) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.disconnectProvider(userId, provider);
      await loadConnections(); // Reload to update UI
    } catch (e) {
      _errorMessage = 'Failed to disconnect ${provider.displayName}: $e';
      debugPrint('WearableConnectionViewModel: Error in disconnectProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if provider's token is still valid
  ///
  /// Returns true if connection exists, is active, and token hasn't expired.
  Future<bool> isTokenValid(WearableProvider provider) async {
    try {
      return await _repository.isTokenValid(userId, provider);
    } catch (e) {
      debugPrint('WearableConnectionViewModel: Error in isTokenValid: $e');
      return false;
    }
  }

  /// Clear error message
  ///
  /// Call this after user acknowledges error to reset error state.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
