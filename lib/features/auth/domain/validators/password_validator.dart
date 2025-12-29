/// Password Validator
///
/// Validates password requirements for user registration and provides
/// real-time strength feedback for UI components.
///
/// Requirements:
/// - Minimum 8 characters
/// - At least 1 uppercase letter
/// - At least 1 lowercase letter
/// - At least 1 number
library;

/// Password strength levels
enum PasswordStrength {
  weak,
  medium,
  strong,
}

/// Password validation result
///
/// Contains validation status and specific error messages for each requirement.
class PasswordValidationResult {
  final bool isValid;
  final bool hasMinimumLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;

  const PasswordValidationResult({
    required this.isValid,
    required this.hasMinimumLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
  });

  /// Returns list of unmet requirements as user-friendly messages
  List<String> get errors {
    final errors = <String>[];
    if (!hasMinimumLength) errors.add('At least 8 characters');
    if (!hasUppercase) errors.add('At least one uppercase letter');
    if (!hasLowercase) errors.add('At least one lowercase letter');
    if (!hasNumber) errors.add('At least one number');
    return errors;
  }

  /// Returns list of met requirements
  List<String> get metRequirements {
    final met = <String>[];
    if (hasMinimumLength) met.add('8+ characters');
    if (hasUppercase) met.add('Uppercase letter');
    if (hasLowercase) met.add('Lowercase letter');
    if (hasNumber) met.add('Number');
    return met;
  }

  /// Creates a result where all requirements pass
  factory PasswordValidationResult.valid() {
    return const PasswordValidationResult(
      isValid: true,
      hasMinimumLength: true,
      hasUppercase: true,
      hasLowercase: true,
      hasNumber: true,
    );
  }
}

/// Static password validator class
///
/// Provides validation methods for password requirements and strength calculation.
class PasswordValidator {
  // Regex patterns for validation
  static final _uppercaseRegex = RegExp(r'[A-Z]');
  static final _lowercaseRegex = RegExp(r'[a-z]');
  static final _numberRegex = RegExp(r'[0-9]');

  // Minimum password length
  static const int minimumLength = 8;

  /// Validates password against all requirements
  ///
  /// Returns a [PasswordValidationResult] with detailed validation status.
  ///
  /// Example:
  /// ```dart
  /// final result = PasswordValidator.validate('MyPass123');
  /// if (result.isValid) {
  ///   // Password meets all requirements
  /// } else {
  ///   // Show errors: result.errors
  /// }
  /// ```
  static PasswordValidationResult validate(String password) {
    final hasMinimumLength = password.length >= minimumLength;
    final hasUppercase = _uppercaseRegex.hasMatch(password);
    final hasLowercase = _lowercaseRegex.hasMatch(password);
    final hasNumber = _numberRegex.hasMatch(password);

    final isValid =
        hasMinimumLength && hasUppercase && hasLowercase && hasNumber;

    return PasswordValidationResult(
      isValid: isValid,
      hasMinimumLength: hasMinimumLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
    );
  }

  /// Calculates password strength
  ///
  /// Strength levels:
  /// - **Weak**: 0-2 requirements met
  /// - **Medium**: 3 requirements met
  /// - **Strong**: All 4 requirements met
  ///
  /// Example:
  /// ```dart
  /// final strength = PasswordValidator.calculateStrength('MyPass123');
  /// // Returns PasswordStrength.strong
  /// ```
  static PasswordStrength calculateStrength(String password) {
    final result = validate(password);
    int score = 0;

    if (result.hasMinimumLength) score++;
    if (result.hasUppercase) score++;
    if (result.hasLowercase) score++;
    if (result.hasNumber) score++;

    if (score >= 4) {
      return PasswordStrength.strong;
    } else if (score == 3) {
      return PasswordStrength.medium;
    } else {
      return PasswordStrength.weak;
    }
  }

  /// Validates password for TextFormField
  ///
  /// Returns null if valid, error message if invalid.
  /// Suitable for use with TextFormField's `validator` property.
  ///
  /// Example:
  /// ```dart
  /// TextFormField(
  ///   validator: PasswordValidator.validateForField,
  ///   decoration: InputDecoration(labelText: 'Password'),
  /// )
  /// ```
  static String? validateForField(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    final result = validate(value);

    if (!result.isValid) {
      return 'Password must meet all requirements';
    }

    return null;
  }

  /// Returns a human-readable description of password requirements
  static String get requirementsDescription {
    return 'Password must contain:\n'
        '• At least 8 characters\n'
        '• At least one uppercase letter (A-Z)\n'
        '• At least one lowercase letter (a-z)\n'
        '• At least one number (0-9)';
  }

  /// Returns a list of requirement strings for UI display
  static List<String> get requirements {
    return [
      'At least 8 characters',
      'At least one uppercase letter',
      'At least one lowercase letter',
      'At least one number',
    ];
  }
}
