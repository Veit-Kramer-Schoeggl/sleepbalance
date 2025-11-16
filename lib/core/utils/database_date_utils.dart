/// Database-specific date utilities
///
/// Handles conversion between Dart DateTime and SQLite TEXT format.
/// SQLite stores dates as ISO 8601 strings for portability and sorting.
///
/// Separation from DateFormatter:
/// - DateFormatter: UI-facing, localized display formats
/// - DatabaseDateUtils: Data layer, ISO 8601 for database operations
class DatabaseDateUtils {
  // Private constructor to prevent instantiation
  DatabaseDateUtils._();

  /// Converts DateTime to database date format (YYYY-MM-DD)
  ///
  /// Example: DateTime(2025, 10, 30) -> "2025-10-30"
  /// Used for date-only columns (action_date, sleep_date, etc.)
  ///
  /// This format ensures proper sorting and date comparison in SQLite.
  static String toDateString(DateTime date) {
    return date.toIso8601String().split('T')[0];
  }

  /// Converts DateTime to full ISO 8601 timestamp
  ///
  /// Example: DateTime.now() -> "2025-10-30T14:30:00.000"
  /// Used for timestamp columns (created_at, updated_at, etc.)
  ///
  /// Preserves full precision including milliseconds.
  static String toTimestamp(DateTime date) {
    return date.toIso8601String();
  }

  /// Parses database string back to DateTime
  ///
  /// Handles both date-only and full timestamp formats:
  /// - "2025-10-30" -> DateTime(2025, 10, 30)
  /// - "2025-10-30T14:30:00.000" -> DateTime(2025, 10, 30, 14, 30, 0, 0)
  ///
  /// Throws FormatException if string is not valid ISO 8601.
  static DateTime fromString(String dateStr) {
    return DateTime.parse(dateStr);
  }

  /// Checks if two dates are the same day (ignoring time)
  ///
  /// Example:
  /// - isSameDay(DateTime(2025, 10, 30, 14, 0), DateTime(2025, 10, 30, 18, 0)) -> true
  /// - isSameDay(DateTime(2025, 10, 30), DateTime(2025, 10, 31)) -> false
  ///
  /// Useful for date-based queries and filtering.
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Gets the start of day (midnight) for a given DateTime
  ///
  /// Example: DateTime(2025, 10, 30, 14, 30) -> DateTime(2025, 10, 30, 0, 0, 0)
  ///
  /// Useful for date range queries.
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Gets the end of day (23:59:59.999) for a given DateTime
  ///
  /// Example: DateTime(2025, 10, 30) -> DateTime(2025, 10, 30, 23, 59, 59, 999)
  ///
  /// Useful for date range queries.
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}