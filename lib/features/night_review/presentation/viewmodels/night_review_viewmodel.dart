import 'package:flutter/foundation.dart';
import 'package:sleepbalance/features/night_review/domain/models/sleep_record.dart';
import 'package:sleepbalance/features/night_review/domain/repositories/sleep_record_repository.dart';
import 'package:sleepbalance/features/settings/domain/repositories/user_repository.dart';

class NightReviewViewmodel extends ChangeNotifier {
  final SleepRecordRepository _repository;
  final UserRepository _userRepository;

  NightReviewViewmodel({
    required SleepRecordRepository repository,
    required UserRepository userRepository
  }) : _repository = repository, _userRepository = userRepository;

  // State
  DateTime? _currentDate;
  SleepRecord? _currentRecord;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters - expose state to UI
  SleepRecord? get currentRecord => _currentRecord;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Map<DateTime, String?>? previousRatings;

  /// Clears any error message
  ///
  /// Useful for dismissing error banners in UI.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> setDateAndFetchRecord(DateTime newDate) async {
    _currentDate = newDate;
    await getRecord();
  }

  Future<void> getRecord() async {
    if (_currentDate == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userId = await _userRepository.getCurrentUserId();
      if (userId == null) throw Exception("User not found");

      _currentRecord = await _repository.getRecordForDate(userId, _currentDate!);
      await _loadPreviousRatings();
    } catch (e) {
      _errorMessage = e.toString();
      _currentRecord = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateRating(String rating) async {
    if (_currentRecord == null) {
      throw Exception("Cannot rate non existent sleep record!");
    }

    await _repository.updateQualityRating(_currentRecord!.id, rating, null);
    await getRecord();
  }

  Future<void> _loadPreviousRatings() async {
    if (_currentDate == null) {
      throw Exception("Current Date must not be null!");
    }

    final userId = await _userRepository.getCurrentUserId();

    previousRatings = await _repository.getPreviousQualityRatings(userId!, _currentDate!);
  }
}
