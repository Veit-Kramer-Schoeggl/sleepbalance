import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/auth/data/services/password_hash_service.dart';

void main() {
  group('PasswordHashService - hashPassword()', () {
    test('Generates a hash for a valid password', () {
      final password = 'MySecurePassword123';
      final hash = PasswordHashService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, isA<String>());
    });

    test('Hash is in PHC format', () {
      final password = 'TestPassword123';
      final hash = PasswordHashService.hashPassword(password);

      // PHC format: $algorithm$version$params$salt$hash
      expect(hash, startsWith('\$argon2id\$'));
      final parts = hash.split('\$');
      expect(parts.length, greaterThanOrEqualTo(5));
    });

    test('Hash contains correct algorithm identifier', () {
      final password = 'TestPassword123';
      final hash = PasswordHashService.hashPassword(password);

      expect(hash, contains('argon2id'));
    });

    test('Hash contains parameters in correct format', () {
      final password = 'TestPassword123';
      final hash = PasswordHashService.hashPassword(password);

      // Should contain memory, time, and parallelism parameters
      expect(hash, contains('m=65536')); // 64 MB memory
      expect(hash, contains('t=3')); // 3 iterations
      expect(hash, contains('p=4')); // 4 parallelism
    });

    test('Different passwords generate different hashes', () {
      final password1 = 'Password123';
      final password2 = 'DifferentPassword456';

      final hash1 = PasswordHashService.hashPassword(password1);
      final hash2 = PasswordHashService.hashPassword(password2);

      expect(hash1, isNot(equals(hash2)));
    });

    test('Same password generates different hashes (due to salt)', () {
      final password = 'SamePassword123';

      final hash1 = PasswordHashService.hashPassword(password);
      final hash2 = PasswordHashService.hashPassword(password);

      // Should be different because of random salt
      expect(hash1, isNot(equals(hash2)));
    });

    test('Can hash empty string', () {
      final hash = PasswordHashService.hashPassword('');

      expect(hash, isNotEmpty);
      expect(hash, startsWith('\$argon2id\$'));
    });

    test('Can hash very long password', () {
      final password = 'A' * 1000;
      final hash = PasswordHashService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, startsWith('\$argon2id\$'));
    });

    test('Can hash password with special characters', () {
      final password = 'P@ssw0rd!#\$%^&*()';
      final hash = PasswordHashService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, startsWith('\$argon2id\$'));
    });

    test('Can hash password with Unicode characters', () {
      final password = 'Pässwörd123';
      final hash = PasswordHashService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, startsWith('\$argon2id\$'));
    });
  });

  group('PasswordHashService - verifyPassword()', () {
    test('Correct password returns true', () {
      final password = 'CorrectPassword123';
      final hash = PasswordHashService.hashPassword(password);

      final isValid = PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Incorrect password returns false', () {
      final password = 'CorrectPassword123';
      final hash = PasswordHashService.hashPassword(password);

      final isValid = PasswordHashService.verifyPassword('WrongPassword456', hash);

      expect(isValid, false);
    });

    test('Empty password verification', () {
      final password = '';
      final hash = PasswordHashService.hashPassword(password);

      final isValid = PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Case-sensitive password verification', () {
      final password = 'Password123';
      final hash = PasswordHashService.hashPassword(password);

      // Different case should fail
      final isValid = PasswordHashService.verifyPassword('password123', hash);

      expect(isValid, false);
    });

    test('Password with extra character fails verification', () {
      final password = 'Password123';
      final hash = PasswordHashService.hashPassword(password);

      final isValid = PasswordHashService.verifyPassword('Password1234', hash);

      expect(isValid, false);
    });

    test('Password missing character fails verification', () {
      final password = 'Password123';
      final hash = PasswordHashService.hashPassword(password);

      final isValid = PasswordHashService.verifyPassword('Password12', hash);

      expect(isValid, false);
    });

    test('Malformed hash returns false instead of throwing', () {
      final password = 'TestPassword123';
      final malformedHash = 'not-a-valid-hash';

      final isValid = PasswordHashService.verifyPassword(password, malformedHash);

      expect(isValid, false);
    });

    test('Empty hash returns false', () {
      final password = 'TestPassword123';

      final isValid = PasswordHashService.verifyPassword(password, '');

      expect(isValid, false);
    });

    test('Verification with special characters', () {
      final password = 'P@ssw0rd!#\$%';
      final hash = PasswordHashService.hashPassword(password);

      final isValid = PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Verification with Unicode characters', () {
      final password = 'Pässwörd123';
      final hash = PasswordHashService.hashPassword(password);

      final isValid = PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });

    test('Very long password verification', () {
      final password = 'A' * 1000;
      final hash = PasswordHashService.hashPassword(password);

      final isValid = PasswordHashService.verifyPassword(password, hash);

      expect(isValid, true);
    });
  });

  group('PasswordHashService - needsRehash()', () {
    test('Freshly hashed password does not need rehash', () {
      final password = 'TestPassword123';
      final hash = PasswordHashService.hashPassword(password);

      final needsRehash = PasswordHashService.needsRehash(hash);

      expect(needsRehash, false);
    });

    test('Hash with different memory parameter needs rehash', () {
      // Simulate old hash with different memory parameter
      final oldHash = '\$argon2id\$v=19\$m=32768,t=3,p=4\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(oldHash);

      expect(needsRehash, true);
    });

    test('Hash with different time parameter needs rehash', () {
      // Simulate old hash with different time parameter
      final oldHash = '\$argon2id\$v=19\$m=65536,t=2,p=4\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(oldHash);

      expect(needsRehash, true);
    });

    test('Hash with different parallelism parameter needs rehash', () {
      // Simulate old hash with different parallelism parameter
      final oldHash = '\$argon2id\$v=19\$m=65536,t=3,p=2\$somesalt\$somehash';

      final needsRehash = PasswordHashService.needsRehash(oldHash);

      expect(needsRehash, true);
    });

    test('Hash with different algorithm needs rehash', () {
      // Simulate hash from different algorithm
      final oldHash = '\$argon2i\$v=19\$m=65536,t=3,p=4\$somesalt\$somehash';

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
      final incompleteHash = '\$argon2id\$v=19\$m=65536';

      final needsRehash = PasswordHashService.needsRehash(incompleteHash);

      expect(needsRehash, true);
    });
  });

  group('PasswordHashService - Integration Tests', () {
    test('Hash and verify workflow', () {
      final password = 'IntegrationTest123';

      // Step 1: Hash password
      final hash = PasswordHashService.hashPassword(password);
      expect(hash, isNotEmpty);

      // Step 2: Verify correct password
      final isCorrect = PasswordHashService.verifyPassword(password, hash);
      expect(isCorrect, true);

      // Step 3: Verify wrong password
      final isWrong = PasswordHashService.verifyPassword('WrongPassword', hash);
      expect(isWrong, false);
    });

    test('Multiple users with same password get different hashes', () {
      final password = 'CommonPassword123';

      final user1Hash = PasswordHashService.hashPassword(password);
      final user2Hash = PasswordHashService.hashPassword(password);
      final user3Hash = PasswordHashService.hashPassword(password);

      // All hashes should be different
      expect(user1Hash, isNot(equals(user2Hash)));
      expect(user1Hash, isNot(equals(user3Hash)));
      expect(user2Hash, isNot(equals(user3Hash)));

      // But all should verify correctly
      expect(PasswordHashService.verifyPassword(password, user1Hash), true);
      expect(PasswordHashService.verifyPassword(password, user2Hash), true);
      expect(PasswordHashService.verifyPassword(password, user3Hash), true);
    });

    test('Rehash workflow', () {
      final password = 'RehashTest123';
      final hash = PasswordHashService.hashPassword(password);

      // Fresh hash shouldn't need rehashing
      expect(PasswordHashService.needsRehash(hash), false);

      // Simulate password change - create new hash
      final newPassword = 'NewPassword456';
      final newHash = PasswordHashService.hashPassword(newPassword);

      // Old password should not verify against new hash
      expect(PasswordHashService.verifyPassword(password, newHash), false);

      // New password should verify against new hash
      expect(PasswordHashService.verifyPassword(newPassword, newHash), true);
    });
  });
}
