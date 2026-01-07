import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/auth/domain/models/email_verification.dart';
import 'package:sleepbalance/features/auth/domain/repositories/auth_repository.dart';
import 'package:sleepbalance/features/auth/domain/repositories/email_verification_repository.dart';
import 'package:sleepbalance/features/auth/domain/validators/password_validator.dart';
import 'package:sleepbalance/features/auth/presentation/viewmodels/signup_viewmodel.dart';
import 'package:sleepbalance/features/settings/domain/models/user.dart';

void main() {
  late SignupViewModel viewModel;
  late _MockAuthRepository mockAuthRepository;
  late _MockEmailVerificationRepository mockEmailVerificationRepository;

  setUp(() {
    mockAuthRepository = _MockAuthRepository();
    mockEmailVerificationRepository = _MockEmailVerificationRepository();
    viewModel = SignupViewModel(
      authRepository: mockAuthRepository,
      emailVerificationRepository: mockEmailVerificationRepository,
    );
  });

  group('Initial State', () {
    test('Initial state is correct', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.createdUser, isNull);
      expect(viewModel.verificationCode, isNull);
    });
  });

  group('validatePassword', () {
    test('Returns valid result for valid password', () {
      final result = viewModel.validatePassword('ValidPass123');

      expect(result.isValid, true);
      expect(result.hasMinimumLength, true);
      expect(result.hasUppercase, true);
      expect(result.hasLowercase, true);
      expect(result.hasNumber, true);
    });

    test('Returns invalid result for weak password', () {
      final result = viewModel.validatePassword('weak');

      expect(result.isValid, false);
      expect(result.errors, isNotEmpty);
    });

    test('Does not change ViewModel state', () {
      final beforeLoading = viewModel.isLoading;
      final beforeError = viewModel.errorMessage;

      viewModel.validatePassword('TestPassword123');

      expect(viewModel.isLoading, beforeLoading);
      expect(viewModel.errorMessage, beforeError);
    });
  });

  group('calculatePasswordStrength', () {
    test('Returns strong for valid password', () {
      final strength = viewModel.calculatePasswordStrength('ValidPass123');

      expect(strength, PasswordStrength.strong);
    });

    test('Returns medium for partially valid password', () {
      final strength = viewModel.calculatePasswordStrength('password123');

      expect(strength, PasswordStrength.medium);
    });

    test('Returns weak for invalid password', () {
      final strength = viewModel.calculatePasswordStrength('weak');

      expect(strength, PasswordStrength.weak);
    });
  });

  group('signupUser', () {
    test('Successful signup sets correct state', () async {
      mockAuthRepository.shouldSucceed = true;
      mockEmailVerificationRepository.verificationCode = '123456';

      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      final success = await viewModel.signupUser(
        email: 'test@example.com',
        password: 'ValidPass123',
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'America/Los_Angeles',
      );

      expect(success, true);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.createdUser, isNotNull);
      expect(viewModel.createdUser!.email, 'test@example.com');
      expect(viewModel.verificationCode, '123456');
      expect(notifyCount, greaterThan(0)); // Should have notified listeners
    });

    test('Invalid password returns false with error', () async {
      final success = await viewModel.signupUser(
        email: 'test@example.com',
        password: 'weak',
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'America/Los_Angeles',
      );

      expect(success, false);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage, contains('Password does not meet requirements'));
      expect(viewModel.createdUser, isNull);
    });

    test('Email already exists returns false with error', () async {
      mockAuthRepository.shouldThrowEmailExists = true;

      final success = await viewModel.signupUser(
        email: 'existing@example.com',
        password: 'ValidPass123',
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'America/Los_Angeles',
      );

      expect(success, false);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage, contains('already exists'));
      expect(viewModel.createdUser, isNull);
    });

    test('Auth exception returns false with error', () async {
      mockAuthRepository.shouldThrowAuthException = true;

      final success = await viewModel.signupUser(
        email: 'test@example.com',
        password: 'ValidPass123',
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'America/Los_Angeles',
      );

      expect(success, false);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage, contains('Registration failed'));
      expect(viewModel.createdUser, isNull);
    });

    test('Generic exception returns false with error', () async {
      mockAuthRepository.shouldThrowGenericException = true;

      final success = await viewModel.signupUser(
        email: 'test@example.com',
        password: 'ValidPass123',
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'America/Los_Angeles',
      );

      expect(success, false);
      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage, contains('unexpected error'));
      expect(viewModel.createdUser, isNull);
    });

    test('Sets loading state correctly during operation', () async {
      mockAuthRepository.shouldSucceed = true;
      mockEmailVerificationRepository.verificationCode = '123456';

      final loadingStates = <bool>[];
      viewModel.addListener(() {
        loadingStates.add(viewModel.isLoading);
      });

      await viewModel.signupUser(
        email: 'test@example.com',
        password: 'ValidPass123',
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'America/Los_Angeles',
      );

      // Should have been true during operation, then false at end
      expect(loadingStates, contains(true));
      expect(loadingStates.last, false);
    });

    test('Clears previous state before new signup', () async {
      // Set some initial state
      mockAuthRepository.shouldSucceed = true;
      mockEmailVerificationRepository.verificationCode = '111111';

      await viewModel.signupUser(
        email: 'first@example.com',
        password: 'ValidPass123',
        firstName: 'First',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
      );

      // Second signup
      mockEmailVerificationRepository.verificationCode = '222222';

      await viewModel.signupUser(
        email: 'second@example.com',
        password: 'ValidPass123',
        firstName: 'Second',
        lastName: 'User',
        birthDate: DateTime(1995, 1, 1),
        timezone: 'UTC',
      );

      expect(viewModel.createdUser!.email, 'second@example.com');
      expect(viewModel.verificationCode, '222222');
    });
  });

  group('clearError', () {
    test('Clears error message and notifies listeners', () {
      // Set an error
      viewModel.signupUser(
        email: 'test@example.com',
        password: 'weak',
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
      );

      expect(viewModel.errorMessage, isNotNull);

      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.clearError();

      expect(viewModel.errorMessage, isNull);
      expect(notified, true);
    });
  });

  group('reset', () {
    test('Resets all state and notifies listeners', () async {
      // Set some state
      mockAuthRepository.shouldSucceed = true;
      mockEmailVerificationRepository.verificationCode = '123456';

      await viewModel.signupUser(
        email: 'test@example.com',
        password: 'ValidPass123',
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
      );

      expect(viewModel.createdUser, isNotNull);
      expect(viewModel.verificationCode, isNotNull);

      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.reset();

      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.createdUser, isNull);
      expect(viewModel.verificationCode, isNull);
      expect(notified, true);
    });
  });
}

// Mock implementations

class _MockAuthRepository implements AuthRepository {
  bool shouldSucceed = false;
  bool shouldThrowEmailExists = false;
  bool shouldThrowAuthException = false;
  bool shouldThrowGenericException = false;

  @override
  Future<User> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String timezone,
  }) async {
    if (shouldThrowEmailExists) {
      throw EmailAlreadyExistsException(email);
    }
    if (shouldThrowAuthException) {
      throw AuthException('Test auth error');
    }
    if (shouldThrowGenericException) {
      throw Exception('Test generic error');
    }
    if (shouldSucceed) {
      final now = DateTime.now();
      return User(
        id: 'test-user-id',
        email: email,
        passwordHash: 'hashed-password',
        firstName: firstName,
        lastName: lastName,
        birthDate: birthDate,
        timezone: timezone,
        emailVerified: false,
        createdAt: now,
        updatedAt: now,
      );
    }
    throw Exception('Mock not configured');
  }

  @override
  Future<void> markEmailVerified(String email) async {}

  @override
  Future<bool> isEmailRegistered(String email) async => false;
}

class _MockEmailVerificationRepository implements EmailVerificationRepository {
  String verificationCode = '123456';

  @override
  Future<String> createVerificationCode(String email) async {
    return verificationCode;
  }

  @override
  Future<bool> verifyCode(String email, String code) async => false;

  @override
  Future<EmailVerification?> getActiveVerification(String email) async => null;

  @override
  Future<void> markAsUsed(String verificationId) async {}

  @override
  Future<void> cleanupExpiredTokens() async {}
}
