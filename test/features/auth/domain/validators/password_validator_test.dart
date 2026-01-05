import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/auth/domain/validators/password_validator.dart';

void main() {
  group('PasswordValidator - validate()', () {
    test('Valid password passes all requirements', () {
      final result = PasswordValidator.validate('ValidPass123');

      expect(result.isValid, true);
      expect(result.hasMinimumLength, true);
      expect(result.hasUppercase, true);
      expect(result.hasLowercase, true);
      expect(result.hasNumber, true);
      expect(result.errors, isEmpty);
    });

    test('Password with minimum 8 characters passes length check', () {
      final result = PasswordValidator.validate('Pass123A');

      expect(result.hasMinimumLength, true);
      expect(result.isValid, true);
    });

    test('Password with 7 characters fails length check', () {
      final result = PasswordValidator.validate('Pas123A');

      expect(result.hasMinimumLength, false);
      expect(result.isValid, false);
      expect(result.errors, contains('At least 8 characters'));
    });

    test('Password without uppercase fails uppercase check', () {
      final result = PasswordValidator.validate('password123');

      expect(result.hasUppercase, false);
      expect(result.isValid, false);
      expect(result.errors, contains('At least one uppercase letter'));
    });

    test('Password without lowercase fails lowercase check', () {
      final result = PasswordValidator.validate('PASSWORD123');

      expect(result.hasLowercase, false);
      expect(result.isValid, false);
      expect(result.errors, contains('At least one lowercase letter'));
    });

    test('Password without number fails number check', () {
      final result = PasswordValidator.validate('PasswordABC');

      expect(result.hasNumber, false);
      expect(result.isValid, false);
      expect(result.errors, contains('At least one number'));
    });

    test('Empty password fails all checks', () {
      final result = PasswordValidator.validate('');

      expect(result.isValid, false);
      expect(result.hasMinimumLength, false);
      expect(result.hasUppercase, false);
      expect(result.hasLowercase, false);
      expect(result.hasNumber, false);
      expect(result.errors.length, 4);
    });

    test('Password with only lowercase fails', () {
      final result = PasswordValidator.validate('password');

      expect(result.isValid, false);
      expect(result.hasLowercase, true);
      expect(result.hasUppercase, false);
      expect(result.hasNumber, false);
    });

    test('Password with special characters still validates correctly', () {
      final result = PasswordValidator.validate('P@ssw0rd!');

      expect(result.isValid, true);
      expect(result.hasMinimumLength, true);
      expect(result.hasUppercase, true);
      expect(result.hasLowercase, true);
      expect(result.hasNumber, true);
    });

    test('Very long password passes validation', () {
      final result = PasswordValidator.validate('VeryLongPassword123WithManyCharacters');

      expect(result.isValid, true);
    });

    test('Password with multiple numbers passes', () {
      final result = PasswordValidator.validate('Pass12345');

      expect(result.hasNumber, true);
      expect(result.isValid, true);
    });

    test('Password with multiple uppercase letters passes', () {
      final result = PasswordValidator.validate('PASSword1');

      expect(result.hasUppercase, true);
      expect(result.isValid, true);
    });

    test('metRequirements returns correct list', () {
      final result = PasswordValidator.validate('ValidPass123');

      expect(result.metRequirements, hasLength(4));
      expect(result.metRequirements, contains('8+ characters'));
      expect(result.metRequirements, contains('Uppercase letter'));
      expect(result.metRequirements, contains('Lowercase letter'));
      expect(result.metRequirements, contains('Number'));
    });

    test('metRequirements is partial when not all requirements met', () {
      final result = PasswordValidator.validate('password');

      expect(result.metRequirements, hasLength(2));
      expect(result.metRequirements, contains('8+ characters'));
      expect(result.metRequirements, contains('Lowercase letter'));
    });
  });

  group('PasswordValidator - calculateStrength()', () {
    test('Strong password (all 4 requirements) returns strong', () {
      final strength = PasswordValidator.calculateStrength('ValidPass123');

      expect(strength, PasswordStrength.strong);
    });

    test('Password with 3 requirements returns medium', () {
      final strength = PasswordValidator.calculateStrength('password1');

      expect(strength, PasswordStrength.medium);
    });

    test('Password with 2 requirements returns weak', () {
      final strength = PasswordValidator.calculateStrength('password');

      expect(strength, PasswordStrength.weak);
    });

    test('Password with 1 requirement returns weak', () {
      final strength = PasswordValidator.calculateStrength('pass');

      expect(strength, PasswordStrength.weak);
    });

    test('Password with 0 requirements returns weak', () {
      final strength = PasswordValidator.calculateStrength('');

      expect(strength, PasswordStrength.weak);
    });

    test('Strong password with special characters still returns strong', () {
      final strength = PasswordValidator.calculateStrength('P@ssw0rd!#');

      expect(strength, PasswordStrength.strong);
    });

    test('Medium password example', () {
      // Has: length (8+), lowercase, number (missing uppercase)
      final strength = PasswordValidator.calculateStrength('password123');

      expect(strength, PasswordStrength.medium);
    });
  });

  group('PasswordValidator - validateForField()', () {
    test('Valid password returns null', () {
      final error = PasswordValidator.validateForField('ValidPass123');

      expect(error, isNull);
    });

    test('Null value returns required error', () {
      final error = PasswordValidator.validateForField(null);

      expect(error, 'Password is required');
    });

    test('Empty value returns required error', () {
      final error = PasswordValidator.validateForField('');

      expect(error, 'Password is required');
    });

    test('Invalid password returns requirements error', () {
      final error = PasswordValidator.validateForField('weak');

      expect(error, 'Password must meet all requirements');
    });

    test('Password missing only uppercase returns requirements error', () {
      final error = PasswordValidator.validateForField('password123');

      expect(error, 'Password must meet all requirements');
    });
  });

  group('PasswordValidator - Static Properties', () {
    test('requirements list has 4 items', () {
      expect(PasswordValidator.requirements, hasLength(4));
    });

    test('requirementsDescription contains all requirements', () {
      final description = PasswordValidator.requirementsDescription;

      expect(description, contains('8 characters'));
      expect(description, contains('uppercase'));
      expect(description, contains('lowercase'));
      expect(description, contains('number'));
    });

    test('minimumLength is 8', () {
      expect(PasswordValidator.minimumLength, 8);
    });
  });

  group('PasswordValidationResult', () {
    test('valid() factory creates all-true result', () {
      final result = PasswordValidationResult.valid();

      expect(result.isValid, true);
      expect(result.hasMinimumLength, true);
      expect(result.hasUppercase, true);
      expect(result.hasLowercase, true);
      expect(result.hasNumber, true);
      expect(result.errors, isEmpty);
    });

    test('errors list is empty when all requirements met', () {
      final result = PasswordValidationResult(
        isValid: true,
        hasMinimumLength: true,
        hasUppercase: true,
        hasLowercase: true,
        hasNumber: true,
      );

      expect(result.errors, isEmpty);
    });

    test('errors list contains all unmet requirements', () {
      final result = PasswordValidationResult(
        isValid: false,
        hasMinimumLength: false,
        hasUppercase: false,
        hasLowercase: true,
        hasNumber: true,
      );

      expect(result.errors, hasLength(2));
      expect(result.errors, contains('At least 8 characters'));
      expect(result.errors, contains('At least one uppercase letter'));
    });
  });

  group('Edge Cases', () {
    test('Password with only numbers fails', () {
      final result = PasswordValidator.validate('12345678');

      expect(result.isValid, false);
      expect(result.hasNumber, true);
      expect(result.hasUppercase, false);
      expect(result.hasLowercase, false);
    });

    test('Password with Unicode characters validates correctly', () {
      final result = PasswordValidator.validate('Pässw0rd');

      expect(result.isValid, true);
    });

    test('Password with spaces validates correctly', () {
      final result = PasswordValidator.validate('Pass word 123');

      expect(result.isValid, true);
    });

    test('Password with tabs and newlines validates correctly', () {
      final result = PasswordValidator.validate('Pass\tword\n123');

      expect(result.isValid, true);
    });

    test('Extremely long password (100+ chars) passes', () {
      final longPassword = 'A' * 50 + 'a' * 50 + '1';
      final result = PasswordValidator.validate(longPassword);

      expect(result.isValid, true);
    });
  });
}
