import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/user_repository.dart';

/// ViewModel for Settings and User Management
///
/// Manages state and business logic for user profile and settings.
/// Extends ChangeNotifier to enable reactive UI updates via Provider.
///
/// Responsibilities:
/// - Load and manage current user state
/// - Handle user profile updates
/// - Manage language and unit system preferences
/// - Handle loading and error states
/// - Notify UI of state changes
class SettingsViewModel extends ChangeNotifier {
  final UserRepository _repository;

  SettingsViewModel({
    required UserRepository repository,
  }) : _repository = repository;

  // State
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters - expose state to UI
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  /// Loads the current user from the repository
  ///
  /// Sets loading state, fetches from repository, handles errors.
  /// Always calls notifyListeners() to update UI.
  /// Should be called on app startup (in SplashScreen).
  Future<void> loadCurrentUser() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final userId = await _repository.getCurrentUserId();
      if (userId != null) {
        _currentUser = await _repository.getUserById(userId);
      }
    } catch (e) {
      _errorMessage = 'Failed to load user: $e';
      debugPrint('SettingsViewModel: Error loading current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates user profile in database
  ///
  /// Updates database, then refreshes current user state.
  /// Automatically sets updatedAt timestamp.
  Future<void> updateUserProfile(User updatedUser) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      // Update user with new timestamp
      final userToUpdate = updatedUser.copyWith(
        updatedAt: DateTime.now(),
      );

      await _repository.updateUser(userToUpdate);
      _currentUser = userToUpdate;
    } catch (e) {
      _errorMessage = 'Failed to update user profile: $e';
      debugPrint('SettingsViewModel: Error updating user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Quick method to update only language preference
  ///
  /// Convenience method that calls updateUserProfile internally.
  /// Updates both database and in-memory state.
  Future<void> updateLanguage(String language) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      notifyListeners();
      return;
    }

    final updatedUser = _currentUser!.copyWith(language: language);
    await updateUserProfile(updatedUser);
  }

  /// Quick method to update only unit system preference
  ///
  /// Convenience method that calls updateUserProfile internally.
  /// Updates both database and in-memory state.
  Future<void> updateUnitSystem(String unitSystem) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      notifyListeners();
      return;
    }

    final updatedUser = _currentUser!.copyWith(preferredUnitSystem: unitSystem);
    await updateUserProfile(updatedUser);
  }

  /// Quick method to update sleep targets
  ///
  /// Updates target sleep duration, bed time, and wake time.
  /// All parameters are optional - only provided values are updated.
  Future<void> updateSleepTargets({
    int? targetSleepDuration,
    String? targetBedTime,
    String? targetWakeTime,
  }) async {
    if (_currentUser == null) {
      _errorMessage = 'No user logged in';
      notifyListeners();
      return;
    }

    final updatedUser = _currentUser!.copyWith(
      targetSleepDuration: targetSleepDuration ?? _currentUser!.targetSleepDuration,
      targetBedTime: targetBedTime ?? _currentUser!.targetBedTime,
      targetWakeTime: targetWakeTime ?? _currentUser!.targetWakeTime,
    );
    await updateUserProfile(updatedUser);
  }

  /// Logs out current user
  ///
  /// Clears current user ID from SharedPreferences and resets state.
  /// Does NOT delete user from database (user data persists).
  /// Terminates the app after successful logout.
  Future<void> logout() async {
    try {
      await _repository.setCurrentUserId('');
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();

      // Terminate app after successful logout
      SystemNavigator.pop();
    } catch (e) {
      _errorMessage = 'Failed to logout: $e';
      debugPrint('SettingsViewModel: Error during logout: $e');
      notifyListeners();
    }
  }

  /// Clears any error message
  ///
  /// Useful for dismissing error banners in UI.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
