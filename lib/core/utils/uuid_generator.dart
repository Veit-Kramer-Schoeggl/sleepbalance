import 'package:uuid/uuid.dart';

/// UUID Generator for local-first database IDs
///
/// Provides UUID v4 generation for creating unique identifiers
/// without server coordination. Essential for offline-first architecture.
class UuidGenerator {
  // Private UUID instance
  static final Uuid _uuid = Uuid();

  // Private constructor to prevent instantiation
  UuidGenerator._();

  /// Generates a new UUID v4 string
  ///
  /// Returns a randomly generated UUID in standard format:
  /// xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
  ///
  /// Example: '550e8400-e29b-41d4-a716-446655440000'
  static String generate() {
    return _uuid.v4();
  }
}
