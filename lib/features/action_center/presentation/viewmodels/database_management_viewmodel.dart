import 'package:flutter/foundation.dart';

import '../../data/services/database_seed_service.dart';

/// ViewModel for database management operations (seed and clear)
///
/// Manages state for development database tools in the Action Center.
/// Provides loading states and error/success messages for UI feedback.
class DatabaseManagementViewModel extends ChangeNotifier {
  bool _isSeeding = false;
  bool _isClearing = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isSeeding => _isSeeding;
  bool get isClearing => _isClearing;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Seeds the database with comprehensive test data
  ///
  /// Creates test user (testuser1@gmail.com / 1234) and sample data
  /// across all database entities.
  Future<void> seedDatabase() async {
    try {
      _isSeeding = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      await DatabaseSeedService.seedDatabase();

      _successMessage = 'Database seeded successfully with test data!';
      debugPrint('DatabaseManagementViewModel: Database seeded successfully');
    } catch (e) {
      _errorMessage = 'Failed to seed database: ${e.toString()}';
      debugPrint('DatabaseManagementViewModel: Seeding error: $e');
    } finally {
      _isSeeding = false;
      notifyListeners();
    }
  }

  /// Clears all data from the database
  ///
  /// Deletes all records from all tables and clears the user session.
  /// This operation cannot be undone.
  Future<void> clearDatabase() async {
    try {
      _isClearing = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      await DatabaseSeedService.clearDatabase();

      _successMessage = 'Database cleared successfully!';
      debugPrint('DatabaseManagementViewModel: Database cleared successfully');
    } catch (e) {
      _errorMessage = 'Failed to clear database: ${e.toString()}';
      debugPrint('DatabaseManagementViewModel: Clear error: $e');
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }

  /// Clears error and success messages
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
