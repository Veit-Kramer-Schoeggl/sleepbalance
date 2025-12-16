import 'package:flutter/foundation.dart';

import '../../domain/enums/wearable_provider.dart';
import '../../domain/exceptions/wearable_exception.dart';
import '../../domain/models/wearable_sync_record.dart';
import '../../domain/repositories/wearable_data_sync_repository.dart';

/// State enum for sync operations
enum SyncState {
  /// No sync in progress, ready to sync
  idle,

  /// Sync currently running
  syncing,

  /// Last sync completed successfully
  success,

  /// Last sync failed with error
  error,
}

/// ViewModel for Wearable Data Sync operations
///
/// Manages state and business logic for syncing sleep data from wearables.
/// Extends ChangeNotifier to enable reactive UI updates via Provider.
///
/// Responsibilities:
/// - Trigger manual sync for date ranges
/// - Track sync progress and results
/// - Manage loading, success, and error states
/// - Load and display last sync information
/// - Notify UI of state changes
class WearableSyncViewModel extends ChangeNotifier {
  final WearableDataSyncRepository _repository;
  final String userId;

  WearableSyncViewModel({
    required WearableDataSyncRepository repository,
    required this.userId,
  }) : _repository = repository;

  // State
  SyncState _state = SyncState.idle;
  WearableSyncRecord? _lastSyncResult;
  String? _errorMessage;

  // Getters - expose state to UI
  SyncState get state => _state;
  WearableSyncRecord? get lastSyncResult => _lastSyncResult;
  String? get errorMessage => _errorMessage;

  bool get isSyncing => _state == SyncState.syncing;
  bool get hasError => _state == SyncState.error;
  bool get isSuccess => _state == SyncState.success;

  /// Whether the error is retryable (network issues, rate limits)
  bool get canRetry {
    if (_state != SyncState.error) return false;
    // Check if the last error was retryable based on error message
    return _errorMessage?.contains('Network') == true ||
        _errorMessage?.contains('rate limit') == true ||
        _errorMessage?.contains('server') == true;
  }

  /// Get the last sync date from the most recent sync result
  DateTime? get lastSyncDate => _lastSyncResult?.syncCompletedAt;

  /// Load the last sync record for display
  ///
  /// Call this on screen init to show last sync information.
  Future<void> loadLastSyncDate() async {
    try {
      _lastSyncResult = await _repository.getLastSync(
        userId: userId,
        provider: WearableProvider.fitbit,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('WearableSyncViewModel: Error loading last sync: $e');
      // Don't set error state - this is just loading cached info
    }
  }

  /// Sync sleep data for the last N days
  ///
  /// Default is 7 days. Sets syncing state, calls repository,
  /// and updates state based on result.
  ///
  /// [days] - Number of days to sync (default: 7)
  Future<void> syncRecentData({int days = 7}) async {
    if (_state == SyncState.syncing) {
      return; // Already syncing, prevent duplicate calls
    }

    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    _state = SyncState.syncing;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.syncSleepData(
        provider: WearableProvider.fitbit,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      _state = SyncState.success;
      _lastSyncResult = result;
      debugPrint(
        'WearableSyncViewModel: Sync completed - '
        'fetched: ${result.recordsFetched}, '
        'inserted: ${result.recordsInserted}, '
        'updated: ${result.recordsUpdated}, '
        'skipped: ${result.recordsSkipped}',
      );
    } on WearableException catch (e) {
      _state = SyncState.error;
      _errorMessage = e.message;
      debugPrint('WearableSyncViewModel: Sync failed - ${e.message}');
    } catch (e) {
      _state = SyncState.error;
      _errorMessage = 'Unexpected error occurred. Please try again.';
      debugPrint('WearableSyncViewModel: Unexpected error - $e');
    } finally {
      notifyListeners();
    }
  }

  /// Clear error state and return to idle
  ///
  /// Call this after user acknowledges error or wants to dismiss message.
  void clearError() {
    _errorMessage = null;
    _state = SyncState.idle;
    notifyListeners();
  }

  /// Clear success state and return to idle
  ///
  /// Call this to dismiss success message while keeping last sync info.
  void clearSuccess() {
    if (_state == SyncState.success) {
      _state = SyncState.idle;
      notifyListeners();
    }
  }
}
