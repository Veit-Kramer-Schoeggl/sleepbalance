import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/auth/domain/models/email_verification.dart';
import 'package:sleepbalance/features/auth/domain/repositories/auth_repository.dart';
import 'package:sleepbalance/features/auth/domain/repositories/email_verification_repository.dart';
import 'package:sleepbalance/features/auth/presentation/viewmodels/email_verification_viewmodel.dart';
import 'package:sleepbalance/features/settings/domain/models/user.dart';

void main() {
  late EmailVerificationViewModel viewModel;
  late _MockEmailVerificationRepository mockEmailVerificationRepository;
  late _MockAuthRepository mockAuthRepository;
  const testEmail = 'test@example.com';

  setUp(() {
    mockEmailVerificationRepository = _MockEmailVerificationRepository();
    mockAuthRepository = _MockAuthRepository();
    viewModel = EmailVerificationViewModel(
      email: testEmail,
      emailVerificationRepository: mockEmailVerificationRepository,
      authRepository: mockAuthRepository,
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('Initial State', () {
    test('Initial state is correct', () {
      expect(viewModel.email, testEmail);
      expect(viewModel.isLoading, false);
      expect(viewModel.isVerifying, false);
      expect(viewModel.isResending, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.secondsRemaining, 0);
      expect(viewModel.hasExpired, true);
    });
  });

  group('loadActiveVerification', () {
    test('Loads active verification and starts timer', () async {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 15));
      mockEmailVerificationRepository.activeVerification = EmailVerification(
        id: 'test-id',
        email: testEmail,
        code: '123456',
        createdAt: now,
        expiresAt: expiresAt,
        isUsed: false,
      );

      await viewModel.loadActiveVerification();

      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.secondsRemaining, greaterThan(0));
      expect(viewModel.hasExpired, false);
    });

    test('Sets error if no active verification found', () async {
      mockEmailVerificationRepository.activeVerification = null;

      await viewModel.loadActiveVerification();

      expect(viewModel.errorMessage, isNotNull);
      expect(viewModel.errorMessage, contains('No active verification'));
    });

    test('Calculates minutes and seconds correctly', () async {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 5, seconds: 30));
      mockEmailVerificationRepository.activeVerification = EmailVerification(
        id: 'test-id',
        email: testEmail,
        code: '123456',
        createdAt: now,
        expiresAt: expiresAt,
        isUsed: false,
      );

      await viewModel.loadActiveVerification();

      expect(viewModel.minutesRemaining, 5);
      expect(viewModel.secondsRemainingInMinute, lessThanOrEqualTo(30));
    });

    test('Notifies listeners during operation', () async {
      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      final now = DateTime.now();
      mockEmailVerificationRepository.activeVerification = EmailVerification(
        id: 'test-id',
        email: testEmail,
        code: '123456',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        isUsed: false,
      );

      await viewModel.loadActiveVerification();

      expect(notifyCount, greaterThan(0));
    });
  });

  group('verifyCode', () {
    test('Successful verification returns true', () async {
      mockEmailVerificationRepository.shouldVerifySucceed = true;

      final success = await viewModel.verifyCode('123456');

      expect(success, true);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isVerifying, false);
    });

    test('Invalid code format returns false with error', () async {
      final success = await viewModel.verifyCode('123');

      expect(success, false);
      expect(viewModel.errorMessage, contains('valid 6-digit code'));
    });

    test('Non-numeric code returns false with error', () async {
      final success = await viewModel.verifyCode('abcdef');

      expect(success, false);
      expect(viewModel.errorMessage, contains('valid 6-digit code'));
    });

    test('Incorrect code returns false with error', () async {
      mockEmailVerificationRepository.shouldVerifySucceed = false;

      final success = await viewModel.verifyCode('123456');

      expect(success, false);
      expect(viewModel.errorMessage, contains('Invalid or expired'));
    });

    test('Marks email as verified after successful verification', () async {
      mockEmailVerificationRepository.shouldVerifySucceed = true;

      await viewModel.verifyCode('123456');

      expect(mockAuthRepository.markedEmailVerified, true);
    });

    test('Sets verifying state correctly during operation', () async {
      mockEmailVerificationRepository.shouldVerifySucceed = true;

      final verifyingStates = <bool>[];
      viewModel.addListener(() {
        verifyingStates.add(viewModel.isVerifying);
      });

      await viewModel.verifyCode('123456');

      expect(verifyingStates, contains(true));
      expect(verifyingStates.last, false);
    });

    test('Handles exception gracefully', () async {
      mockEmailVerificationRepository.shouldThrowException = true;

      final success = await viewModel.verifyCode('123456');

      expect(success, false);
      expect(viewModel.errorMessage, contains('Verification failed'));
    });
  });

  group('resendCode', () {
    test('Successfully resends code and reloads verification', () async {
      mockEmailVerificationRepository.newVerificationCode = '654321';

      final now = DateTime.now();
      mockEmailVerificationRepository.activeVerification = EmailVerification(
        id: 'new-id',
        email: testEmail,
        code: '654321',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        isUsed: false,
      );

      final success = await viewModel.resendCode();

      expect(success, true);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.isResending, false);
      expect(viewModel.secondsRemaining, greaterThan(0));
    });

    test('Sets resending state correctly during operation', () async {
      mockEmailVerificationRepository.newVerificationCode = '654321';

      final now = DateTime.now();
      mockEmailVerificationRepository.activeVerification = EmailVerification(
        id: 'new-id',
        email: testEmail,
        code: '654321',
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 15)),
        isUsed: false,
      );

      final resendingStates = <bool>[];
      viewModel.addListener(() {
        resendingStates.add(viewModel.isResending);
      });

      await viewModel.resendCode();

      expect(resendingStates, contains(true));
      expect(resendingStates.last, false);
    });

    test('Handles exception gracefully', () async {
      mockEmailVerificationRepository.shouldThrowOnCreate = true;

      final success = await viewModel.resendCode();

      expect(success, false);
      expect(viewModel.errorMessage, contains('Failed to resend'));
    });
  });

  group('clearError', () {
    test('Clears error message and notifies listeners', () async {
      // Set an error
      await viewModel.verifyCode('123');

      expect(viewModel.errorMessage, isNotNull);

      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.clearError();

      expect(viewModel.errorMessage, isNull);
      expect(notified, true);
    });
  });

  group('Timer Functionality', () {
    test('Timer updates seconds remaining', () async {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(seconds: 5));
      mockEmailVerificationRepository.activeVerification = EmailVerification(
        id: 'test-id',
        email: testEmail,
        code: '123456',
        createdAt: now,
        expiresAt: expiresAt,
        isUsed: false,
      );

      await viewModel.loadActiveVerification();

      final initialSeconds = viewModel.secondsRemaining;

      await Future.delayed(const Duration(seconds: 2));

      expect(viewModel.secondsRemaining, lessThan(initialSeconds));
    });

    test('Timer stops when verification expires', () async {
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(seconds: 2));
      mockEmailVerificationRepository.activeVerification = EmailVerification(
        id: 'test-id',
        email: testEmail,
        code: '123456',
        createdAt: now,
        expiresAt: expiresAt,
        isUsed: false,
      );

      await viewModel.loadActiveVerification();

      await Future.delayed(const Duration(seconds: 3));

      expect(viewModel.secondsRemaining, 0);
      expect(viewModel.hasExpired, true);
      expect(viewModel.errorMessage, contains('expired'));
    });

    test('Dispose stops timer', () async {
      // Create a separate viewModel instance for this test to avoid double dispose
      final testViewModel = EmailVerificationViewModel(
        email: testEmail,
        emailVerificationRepository: mockEmailVerificationRepository,
        authRepository: mockAuthRepository,
      );

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(minutes: 15));
      mockEmailVerificationRepository.activeVerification = EmailVerification(
        id: 'test-id',
        email: testEmail,
        code: '123456',
        createdAt: now,
        expiresAt: expiresAt,
        isUsed: false,
      );

      await testViewModel.loadActiveVerification();
      expect(testViewModel.secondsRemaining, greaterThan(0));

      testViewModel.dispose();

      // Timer should be stopped, no crashes
      await Future.delayed(const Duration(seconds: 2));
    });
  });
}

// Mock implementations

class _MockEmailVerificationRepository implements EmailVerificationRepository {
  EmailVerification? activeVerification;
  String newVerificationCode = '123456';
  bool shouldVerifySucceed = false;
  bool shouldThrowException = false;
  bool shouldThrowOnCreate = false;

  @override
  Future<String> createVerificationCode(String email) async {
    if (shouldThrowOnCreate) {
      throw Exception('Test exception');
    }
    return newVerificationCode;
  }

  @override
  Future<bool> verifyCode(String email, String code) async {
    if (shouldThrowException) {
      throw Exception('Test exception');
    }
    return shouldVerifySucceed;
  }

  @override
  Future<EmailVerification?> getActiveVerification(String email) async {
    return activeVerification;
  }

  @override
  Future<void> markAsUsed(String verificationId) async {}

  @override
  Future<void> cleanupExpiredTokens() async {}
}

class _MockAuthRepository implements AuthRepository {
  bool markedEmailVerified = false;

  @override
  Future<void> markEmailVerified(String email) async {
    markedEmailVerified = true;
  }

  @override
  Future<User> registerUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
    required String timezone,
  }) async =>
      throw UnimplementedError();

  @override
  Future<bool> isEmailRegistered(String email) async => false;
}
