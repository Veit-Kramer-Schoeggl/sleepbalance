import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _germanDateFormat = DateFormat('EEEE, dd.MM.yyyy', 'de_DE');
  static final DateFormat _englishDateFormat = DateFormat('EEEE, MMM dd, yyyy', 'en_US');
  static final DateFormat _germanWeekdayFormat = DateFormat('EEEE', 'de_DE');
  static final DateFormat _englishWeekdayFormat = DateFormat('EEEE', 'en_US');

  /// Formats date for German locale (24-hour format)
  /// Example: "Dienstag, 29.10.2024"
  static String formatDateGerman(DateTime date) {
    return _germanDateFormat.format(date);
  }

  /// Formats date for English locale (12-hour AM/PM format)
  /// Example: "Tuesday, Oct 29, 2024"
  static String formatDateEnglish(DateTime date) {
    return _englishDateFormat.format(date);
  }

  /// Auto-detects system locale and formats accordingly
  /// Falls back to English if locale detection fails
  static String formatDateLocalized(DateTime date) {
    final String locale = Intl.getCurrentLocale();
    
    if (locale.startsWith('de')) {
      return formatDateGerman(date);
    } else {
      return formatDateEnglish(date);
    }
  }

  /// Gets weekday name in German
  /// Example: "Dienstag"
  static String getWeekdayNameGerman(DateTime date) {
    return _germanWeekdayFormat.format(date);
  }

  /// Gets weekday name in English
  /// Example: "Tuesday"
  static String getWeekdayNameEnglish(DateTime date) {
    return _englishWeekdayFormat.format(date);
  }

  /// Gets weekday name based on system locale
  static String getWeekdayNameLocalized(DateTime date) {
    final String locale = Intl.getCurrentLocale();
    
    if (locale.startsWith('de')) {
      return getWeekdayNameGerman(date);
    } else {
      return getWeekdayNameEnglish(date);
    }
  }

  /// Formats date for display in the navigation header
  /// Returns format: "Weekday, Date"
  /// Example: "Tuesday, Oct 29" or "Dienstag, 29.10"
  static String formatForHeader(DateTime date) {
    final String locale = Intl.getCurrentLocale();
    
    if (locale.startsWith('de')) {
      final weekday = getWeekdayNameGerman(date);
      final dateStr = DateFormat('dd.MM', 'de_DE').format(date);
      return '$weekday, $dateStr';
    } else {
      final weekday = getWeekdayNameEnglish(date);
      final dateStr = DateFormat('MMM dd', 'en_US').format(date);
      return '$weekday, $dateStr';
    }
  }
}