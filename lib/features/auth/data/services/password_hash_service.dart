import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:argon2_ffi_base/argon2_ffi_base.dart';

/// Password Hash Service
///
/// Provides secure password hashing using Argon2id algorithm.
/// Uses native FFI implementation for optimal performance.
///
/// Security Parameters:
/// - Algorithm: Argon2id (type=2, hybrid of Argon2i and Argon2d)
/// - Time cost: 3 iterations
/// - Memory cost: 65536 KB (64 MB)
/// - Parallelism: 4 threads
/// - Salt length: 16 bytes (auto-generated)
/// - Hash length: 32 bytes
///
/// Hash Format: PHC string format
/// ```
/// $argon2id$v=19$m=65536,t=3,p=4$<base64_salt>$<base64_hash>
/// ```
class PasswordHashService {
  // Argon2 parameters for password hashing
  static const int _timeCost = 3; // iterations
  static const int _memoryCost = 65536; // KB (64 MB)
  static const int _parallelism = 4; // threads
  static const int _hashLength = 32; // bytes
  static const int _saltLength = 16; // bytes
  static const int _argon2Type = 2; // Argon2id
  static const int _argon2Version = 19; // Version 1.3

  static final _argon2 = Argon2FfiFlutter();
  static final _random = Random.secure();

  /// Hashes a password using Argon2id
  ///
  /// Generates a secure hash with auto-generated random salt.
  /// The salt is embedded in the returned hash string.
  ///
  /// Returns PHC format string containing algorithm parameters, salt, and hash.
  /// This string can be stored directly in the database.
  ///
  /// Example:
  /// ```dart
  /// final hash = PasswordHashService.hashPassword('MySecurePassword123');
  /// // Returns: $argon2id$v=19$m=65536,t=3,p=4$...
  /// ```
  ///
  /// Note: Each call generates a different hash due to random salt,
  /// even for the same password.
  static String hashPassword(String password) {
    try {
      // Generate random salt
      final salt = _generateSalt();

      // Convert password to bytes
      final passwordBytes = Uint8List.fromList(utf8.encode(password));

      // Create Argon2 arguments
      final args = Argon2Arguments(
        passwordBytes,
        salt,
        _memoryCost,
        _timeCost,
        _hashLength,
        _parallelism,
        _argon2Type,
        _argon2Version,
      );

      // Hash password
      final hash = _argon2.argon2(args);

      // Encode to PHC format
      return _encodePHC(salt, hash);
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
  /// final isValid = PasswordHashService.verifyPassword(
  ///   'MySecurePassword123',
  ///   storedHash,
  /// );
  /// if (isValid) {
  ///   // Password correct
  /// }
  /// ```
  ///
  /// Note: This method is timing-safe - it takes approximately the same
  /// time regardless of whether the password matches or not.
  static bool verifyPassword(String password, String storedHash) {
    try {
      // Parse PHC format hash
      final parsed = _parsePHC(storedHash);
      if (parsed == null) {
        return false;
      }

      final salt = parsed['salt'] as Uint8List;
      final expectedHash = parsed['hash'] as Uint8List;

      // Convert password to bytes
      final passwordBytes = Uint8List.fromList(utf8.encode(password));

      // Create Argon2 arguments with same parameters
      final args = Argon2Arguments(
        passwordBytes,
        salt,
        _memoryCost,
        _timeCost,
        _hashLength,
        _parallelism,
        _argon2Type,
        _argon2Version,
      );

      // Compute hash
      final actualHash = _argon2.argon2(args);

      // Constant-time comparison
      return _constantTimeCompare(expectedHash, actualHash);
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
      // Parse PHC format string to extract parameters
      final parts = storedHash.split('\$');
      if (parts.length < 5) return true;

      // Check algorithm (should be argon2id)
      if (parts[1] != 'argon2id') return true;

      // Check version
      final versionPart = parts[2];
      if (!versionPart.startsWith('v=')) return true;
      final version = int.tryParse(versionPart.substring(2)) ?? 0;
      if (version != _argon2Version) return true;

      // Parse parameters from format: m=65536,t=3,p=4
      final params = parts[3];
      final paramMap = <String, int>{};

      for (final param in params.split(',')) {
        final keyValue = param.split('=');
        if (keyValue.length == 2) {
          paramMap[keyValue[0]] = int.tryParse(keyValue[1]) ?? 0;
        }
      }

      // Check if any parameter differs from current configuration
      return paramMap['m'] != _memoryCost ||
          paramMap['t'] != _timeCost ||
          paramMap['p'] != _parallelism;
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

  /// Encodes salt and hash to PHC format string
  static String _encodePHC(Uint8List salt, Uint8List hash) {
    final saltEncoded = base64.encode(salt).replaceAll('=', '');
    final hashEncoded = base64.encode(hash).replaceAll('=', '');

    return '\$argon2id\$v=$_argon2Version\$'
        'm=$_memoryCost,t=$_timeCost,p=$_parallelism\$'
        '$saltEncoded\$$hashEncoded';
  }

  /// Parses PHC format string to extract salt and hash
  static Map<String, dynamic>? _parsePHC(String phcString) {
    try {
      final parts = phcString.split('\$');
      if (parts.length < 5) return null;

      // parts[0] is empty (before first $)
      // parts[1] is algorithm (argon2id)
      // parts[2] is version (v=19)
      // parts[3] is parameters (m=65536,t=3,p=4)
      // parts[4] is salt (base64)
      // parts[5] is hash (base64)

      if (parts[1] != 'argon2id') return null;
      if (parts.length < 6) return null;

      // Decode salt and hash (add padding if needed)
      final saltB64 = _addBase64Padding(parts[4]);
      final hashB64 = _addBase64Padding(parts[5]);

      final salt = base64.decode(saltB64);
      final hash = base64.decode(hashB64);

      return {
        'salt': Uint8List.fromList(salt),
        'hash': Uint8List.fromList(hash),
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
