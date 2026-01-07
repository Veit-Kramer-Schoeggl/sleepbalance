import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/auth/data/services/password_hash_service.dart';

void main() {
  group('PasswordHashService - hashPassword()', () {
    test('Generates a hash for a valid password', () async {
      final password = 'MySecurePassword123';
      final hash = await PasswordHashService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, isA<String>());
    });

    test('Hash is in PHC format', () async {
      final password = 'TestPassword123';
      final hash = await PasswordHashService.hashPassword(password);

      // PHC format: $algorithm$version$iterations$salt$hash
      expect(hash, startsWith('\$pbkdf2-sha256\$'));
      final parts = hash.split('\$');
      expect(parts.length, greaterThanOrEqualTo(6));
    });

    test('Hash contains correct algorithm identifier', () async {
      final password = 'TestPassword123';
      final hash = await PasswordHashService.hashPassword(password);

      expect(hash, contains('pbkdf2-sha256'));
    });

    test('Hash contains parameters in correct format', () async {
      final password = 'TestPassword123';
      final hash = await PasswordHashService.hashPassword(password);

      // Should contain version and iteration count
      expect(hash, contains('v=1')); // Format version
      expect(hash, contains('i=600000')); // 600,000 iterations
    });

    test('Different passwords generate different hashes', () async {
      final password1 = 'Password123';
      final password2 = 'DifferentPassword456';

      final hash1 = await PasswordHashService.hashPassword(password1);
      final hash2 = await PasswordHashService.hashPassword(password2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('Same password generates different hashes (due to salt)', () async {
      final password = 'SamePassword123';

      final hash1 = await PasswordHashService.hashPassword(password);
      final hash2 = await PasswordHashService.hashPassword(password);

      // Should be different because of random salt
      expect(hash1, isNot(equals(hash2)));
    });

    test('Can hash empty string', () async {
      final hash = await PasswordHashService.hashPassword('');

      expect(hash, isNotEmpty);
      expect(hash, startsWith('\$pbkdf2-sha256\$'));
    });

    test('Can hash very long password', () async {
      final password = 'A' * 1000;
      final hash = await PasswordHashService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, startsWith('\$pbkdf2-sha256\$'));
    });

    test('Can hash password with special characters', () async {
      final password = 'P@ssw0rd!#\$%^&*()';
      final hash = await PasswordHashService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, startsWith('\$pbkdf2-sha256\$'));
    });

    test('Can hash password with Unicode characters', () async {
      final password = 'Pässwörd123';
      final hash = await PasswordHashService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, startsWith('\$pbkdf2-sha256\$'));
    });
  });

  group('PasswordHashService - verifyPassword()', () {
    test('Correct password returns true', () async {
      final password = 'CorrectPassword123';
      final hash = await PasswordHashService.hashPassword(password);

      final isValid = await PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Incorrect password returns false', () async {
      final password = 'CorrectPassword123';
      final hash = await PasswordHashService.hashPassword(password);

      final isValid = await PasswordHashService.verifyPassword('WrongPassword456', hash);

      expect(isValid, false);
    });

    test('Empty password verification', () async {
      final password = '';
      final hash = await PasswordHashService.hashPassword(password);

      final isValid = await PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Case-sensitive password verification', () async {
      final password = 'Password123';
      final hash = await PasswordHashService.hashPassword(password);

      // Different case should fail
      final isValid = await PasswordHashService.verifyPassword('password123', hash);

      expect(isValid, false);
    });

    test('Password with extra character fails verification', () async {
      final password = 'Password123';
      final hash = await PasswordHashService.hashPassword(password);

      final isValid = await PasswordHashService.verifyPassword('Password1234', hash);

      expect(isValid, false);
    });

    test('Password missing character fails verification', () async {
      final password = 'Password123';
      final hash = await PasswordHashService.hashPassword(password);

      final isValid = await PasswordHashService.verifyPassword('Password12', hash);

      expect(isValid, false);
    });

    test('Malformed hash returns false instead of throwing', () async {
      final password = 'TestPassword123';
      final malformedHash = 'not-a-valid-hash';

      final isValid = await PasswordHashService.verifyPassword(password, malformedHash);

      expect(isValid, false);
    });

    test('Empty hash returns false', () async {
      final password = 'TestPassword123';

      final isValid = await PasswordHashService.verifyPassword(password, '');

      expect(isValid, false);
    });

    test('Verification with special characters', () async {
      final password = 'P@ssw0rd!#\$%';
      final hash = await PasswordHashService.hashPassword(password);

      final isValid = await PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Verification with Unicode characters', () async {
      final password = 'Pässwörd123';
      final hash = await PasswordHashService.hashPassword(password);

      final isValid = await PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Very long password verification', () async {
      final password = 'A' * 1000;
      final hash = await PasswordHashService.hashPassword(password);

      final isValid = await PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });
  });

  group('PasswordHashService - needsRehash()', () {
    test('Freshly hashed password does not need rehash', () async {
      final password = 'TestPassword123';
      final hash = await PasswordHashService.hashPassword(password);

      final needsRehash = PasswordHashService.needsRehash(hash);

      expect(needsRehash, false);
    });

    test('Hash with different iteration count needs rehash', () {
      // Simulate old hash with different iteration count
      final oldHash = '\$pbkdf2-sha256\$v=1\$i=100000\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(oldHash);

      expect(needsRehash, true);
    });

    test('Hash with lower iteration count needs rehash', () {
      // Simulate old hash with lower iteration count
      final oldHash = '\$pbkdf2-sha256\$v=1\$i=310000\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(oldHash);

      expect(needsRehash, true);
    });

    test('Hash with different algorithm needs rehash', () {
      // Simulate hash from Argon2id (old algorithm)
      final oldHash = '\$argon2id\$v=19\$m=65536,t=3,p=4\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(oldHash);

      expect(needsRehash, true);
    });

    test('Hash with different version needs rehash', () {
      // Simulate hash with old format version
      final oldHash = '\$pbkdf2-sha256\$v=0\$i=600000\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(oldHash);

      expect(needsRehash, true);
    });

    test('Malformed hash needs rehash', () {
      final malformedHash = 'not-a-valid-hash';

      final needsRehash = PasswordHashService.needsRehash(malformedHash);

      expect(needsRehash, true);
    });

    test('Empty hash needs rehash', () {
      final needsRehash = PasswordHashService.needsRehash('');

      expect(needsRehash, true);
    });

    test('Hash with missing parameters needs rehash', () {
      final incompleteHash = '\$pbkdf2-sha256\$v=1\$i=600000';

      final needsRehash = PasswordHashService.needsRehash(incompleteHash);

      expect(needsRehash, true);
    });

    test('Hash with missing version needs rehash', () {
      final noVersionHash = '\$pbkdf2-sha256\$i=600000\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(noVersionHash);

      expect(needsRehash, true);
    });

    test('Hash with malformed iteration parameter needs rehash', () {
      final badIterHash = '\$pbkdf2-sha256\$v=1\$iterations=600000\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(badIterHash);

      expect(needsRehash, true);
    });
  });

  group('PasswordHashService - Integration Tests', () {
    test('Hash and verify workflow', () async {
      final password = 'IntegrationTest123';

      // Step 1: Hash password
      final hash = await PasswordHashService.hashPassword(password);
      expect(hash, isNotEmpty);

      // Step 2: Verify correct password
      final isCorrect = await PasswordHashService.verifyPassword(password, hash);
      expect(isCorrect, true);

      // Step 3: Verify wrong password
      final isWrong = await PasswordHashService.verifyPassword('WrongPassword', hash);
      expect(isWrong, false);
    });

    test('Multiple users with same password get different hashes', () async {
      final password = 'CommonPassword123';

      final user1Hash = await PasswordHashService.hashPassword(password);
      final user2Hash = await PasswordHashService.hashPassword(password);
      final user3Hash = await PasswordHashService.hashPassword(password);

      // All hashes should be different
      expect(user1Hash, isNot(equals(user2Hash)));
      expect(user1Hash, isNot(equals(user3Hash)));
      expect(user2Hash, isNot(equals(user3Hash)));

      // But all should verify correctly
      expect(await PasswordHashService.verifyPassword(password, user1Hash), true);
      expect(await PasswordHashService.verifyPassword(password, user2Hash), true);
      expect(await PasswordHashService.verifyPassword(password, user3Hash), true);
    });

    test('Rehash workflow', () async {
      final password = 'RehashTest123';
      final hash = await PasswordHashService.hashPassword(password);

      // Fresh hash shouldn't need rehashing
      expect(PasswordHashService.needsRehash(hash), false);

      // Simulate password change - create new hash
      final newPassword = 'NewPassword456';
      final newHash = await PasswordHashService.hashPassword(newPassword);

      // Old password should not verify against new hash
      expect(await PasswordHashService.verifyPassword(password, newHash), false);

      // New password should verify against new hash
      expect(await PasswordHashService.verifyPassword(newPassword, newHash), true);
    });

    test('Cross-algorithm compatibility - Argon2 hash needs rehash', () {
      // Simulate existing Argon2id hash in database
      final argon2Hash = '\$argon2id\$v=19\$m=65536,t=3,p=4\$c29tZXNhbHQ\$c29tZWhhc2g';

      // Should detect as needing rehash
      expect(PasswordHashService.needsRehash(argon2Hash), true);
    });

    test('PBKDF2 hash format validation', () async {
      final password = 'FormatTest123';
      final hash = await PasswordHashService.hashPassword(password);

      // Split and validate format
      final parts = hash.split('\$');

      // parts[0] should be empty (before first $)
      expect(parts[0], isEmpty);

      // parts[1] should be algorithm
      expect(parts[1], equals('pbkdf2-sha256'));

      // parts[2] should be version
      expect(parts[2], startsWith('v='));
      expect(parts[2], equals('v=1'));

      // parts[3] should be iterations
      expect(parts[3], startsWith('i='));
      expect(parts[3], equals('i=600000'));

      // parts[4] should be base64 salt (no padding)
      expect(parts[4], isNotEmpty);
      expect(parts[4], isNot(contains('=')));

      // parts[5] should be base64 hash (no padding)
      expect(parts[5], isNotEmpty);
      expect(parts[5], isNot(contains('=')));
    });
  });
}
