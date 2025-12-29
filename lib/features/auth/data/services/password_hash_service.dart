import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Password Hash Service
///
/// Provides secure password hashing using PBKDF2-HMAC-SHA256 algorithm.
/// Pure Dart implementation with no native dependencies.
///
/// Security Parameters:
/// - Algorithm: PBKDF2-HMAC-SHA256
/// - Iterations: 600,000 (OWASP 2023 recommendation)
/// - Salt length: 16 bytes (auto-generated)
/// - Hash length: 32 bytes
///
/// Hash Format: PHC-inspired string format
/// ```
/// $pbkdf2-sha256$v=1$i=600000$<base64_salt>$<base64_hash>
/// ```
class PasswordHashService {
  // PBKDF2 parameters for password hashing
  static const int _iterations = 600000; // OWASP 2023 recommendation
  static const int _formatVersion = 1;
  static const String _algorithmId = 'pbkdf2-sha256';
  static const int _hashLength = 32; // bytes
  static const int _saltLength = 16; // bytes

  static final _random = Random.secure();

  /// Hashes a password using PBKDF2-HMAC-SHA256
  ///
  /// Generates a secure hash with auto-generated random salt.
  /// The salt is embedded in the returned hash string.
  ///
  /// Returns PHC-inspired format string containing algorithm parameters, salt, and hash.
  /// This string can be stored directly in the database.
  ///
  /// Example:
  /// ```dart
  /// final hash = await PasswordHashService.hashPassword('MySecurePassword123');
  /// // Returns: $pbkdf2-sha256$v=1$i=600000$...
  /// ```
  ///
  /// Note: Each call generates a different hash due to random salt,
  /// even for the same password. This method is asynchronous due to the
  /// computationally intensive nature of PBKDF2.
  static Future<String> hashPassword(String password) async {
    try {
      // Generate random salt
      final salt = _generateSalt();

      // Hash password using PBKDF2
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: _iterations,
        bits: _hashLength * 8, // 256 bits
      );

      // Derive key from password
      final secretKey = await pbkdf2.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );

      // Extract bytes from secret key
      final hashBytes = await secretKey.extractBytes();

      // Encode to PHC format
      return _encodePHC(salt, Uint8List.fromList(hashBytes));
    } catch (e) {
      throw PasswordHashException(
        'Failed to hash password: ${e.toString()}',
        e,
      );
    }
  }

  /// Verifies a password against a stored hash
  ///
  /// Extracts salt and parameters from the stored hash and computes
  /// a new hash with the provided password. Returns true if hashes match.
  ///
  /// Parameters:
  /// - [password]: The plain text password to verify
  /// - [storedHash]: The PHC format hash string from database
  ///
  /// Returns true if password matches, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final isValid = await PasswordHashService.verifyPassword(
  ///   'MySecurePassword123',
  ///   storedHash,
  /// );
  /// if (isValid) {
  ///   // Password correct
  /// }
  /// ```
  ///
  /// Note: This method is timing-safe - it takes approximately the same
  /// time regardless of whether the password matches or not. This method
  /// is asynchronous due to the computationally intensive nature of PBKDF2.
  static Future<bool> verifyPassword(String password, String storedHash) async {
    try {
      // Parse PHC format hash
      final parsed = _parsePHC(storedHash);
      if (parsed == null) {
        return false;
      }

      final salt = parsed['salt'] as Uint8List;
      final expectedHash = parsed['hash'] as Uint8List;
      final iterations = parsed['iterations'] as int;

      // Hash password with same parameters
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac.sha256(),
        iterations: iterations,
        bits: _hashLength * 8,
      );

      // Derive key from password
      final secretKey = await pbkdf2.deriveKeyFromPassword(
        password: password,
        nonce: salt,
      );

      // Extract bytes from secret key
      final actualHashBytes = await secretKey.extractBytes();

      // Constant-time comparison
      return _constantTimeCompare(expectedHash, Uint8List.fromList(actualHashBytes));
    } catch (e) {
      // If verification fails due to malformed hash or other error,
      // return false rather than throwing
      return false;
    }
  }

  /// Checks if a hash needs rehashing due to updated parameters
  ///
  /// Returns true if the stored hash uses different parameters than
  /// the current configuration, indicating it should be rehashed.
  ///
  /// This allows for graceful parameter upgrades:
  /// 1. User logs in successfully
  /// 2. Check if hash needs rehashing
  /// 3. If yes, rehash with new parameters and update database
  ///
  /// Example:
  /// ```dart
  /// if (PasswordHashService.needsRehash(user.passwordHash)) {
  ///   final newHash = PasswordHashService.hashPassword(plainPassword);
  ///   await updateUserPasswordHash(user.id, newHash);
  /// }
  /// ```
  static bool needsRehash(String storedHash) {
    try {
      // Parse PHC format string
      final parts = storedHash.split('\$');
      if (parts.length < 5) return true;

      // Check algorithm (should be pbkdf2-sha256)
      if (parts[1] != _algorithmId) return true;

      // Check version
      final versionPart = parts[2];
      if (!versionPart.startsWith('v=')) return true;
      final version = int.tryParse(versionPart.substring(2)) ?? 0;
      if (version != _formatVersion) return true;

      // Parse iterations from format: i=600000
      final iterationsPart = parts[3];
      if (!iterationsPart.startsWith('i=')) return true;
      final iterations = int.tryParse(iterationsPart.substring(2)) ?? 0;

      // Check if iterations differ from current configuration
      return iterations != _iterations;
    } catch (e) {
      // If parsing fails, assume rehash is needed
      return true;
    }
  }

  // Private helper methods

  /// Generates a cryptographically secure random salt
  static Uint8List _generateSalt() {
    final salt = Uint8List(_saltLength);
    for (var i = 0; i < _saltLength; i++) {
      salt[i] = _random.nextInt(256);
    }
    return salt;
  }

  /// Encodes salt and hash to PHC-inspired format string
  static String _encodePHC(Uint8List salt, Uint8List hash) {
    final saltEncoded = base64.encode(salt).replaceAll('=', '');
    final hashEncoded = base64.encode(hash).replaceAll('=', '');

    return '\$$_algorithmId\$v=$_formatVersion\$'
        'i=$_iterations\$'
        '$saltEncoded\$$hashEncoded';
  }

  /// Parses PHC format string to extract salt, hash, and iterations
  static Map<String, dynamic>? _parsePHC(String phcString) {
    try {
      final parts = phcString.split('\$');
      if (parts.length < 6) return null;

      // parts[0] is empty (before first $)
      // parts[1] is algorithm (pbkdf2-sha256)
      // parts[2] is version (v=1)
      // parts[3] is iterations (i=600000)
      // parts[4] is salt (base64)
      // parts[5] is hash (base64)

      if (parts[1] != _algorithmId) return null;

      // Extract iterations
      final iterationsPart = parts[3];
      if (!iterationsPart.startsWith('i=')) return null;
      final iterations = int.tryParse(iterationsPart.substring(2));
      if (iterations == null) return null;

      // Decode salt and hash (add padding if needed)
      final saltB64 = _addBase64Padding(parts[4]);
      final hashB64 = _addBase64Padding(parts[5]);

      final salt = base64.decode(saltB64);
      final hash = base64.decode(hashB64);

      return {
        'salt': Uint8List.fromList(salt),
        'hash': Uint8List.fromList(hash),
        'iterations': iterations,
      };
    } catch (e) {
      return null;
    }
  }

  /// Adds padding to base64 string if needed
  static String _addBase64Padding(String base64String) {
    final padding = (4 - base64String.length % 4) % 4;
    return base64String + ('=' * padding);
  }

  /// Constant-time comparison of two byte arrays
  ///
  /// Prevents timing attacks by always comparing all bytes
  static bool _constantTimeCompare(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }

    return result == 0;
  }
}

/// Exception thrown when password hashing fails
class PasswordHashException implements Exception {
  final String message;
  final dynamic originalError;

  PasswordHashException(this.message, [this.originalError]);

  @override
  String toString() => 'PasswordHashException: $message';
}
