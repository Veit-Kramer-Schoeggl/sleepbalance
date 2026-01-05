import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/features/auth/data/services/password_hash_service.dart';
import 'package:sleepbalance/features/auth/presentation/viewmodels/login_viewmodel.dart';
import 'package:sleepbalance/features/settings/domain/models/user.dart';
import 'package:sleepbalance/features/settings/domain/repositories/user_repository.dart';

void main() {
  late LoginViewModel viewModel;
  late _MockUserRepository mockUserRepository;
  late String testPasswordHash;

  const testEmail = 'test@example.com';
  const testPassword = 'TestPassword123';

  // Generate real password hash once before all tests
  setUpAll(() async {
    testPasswordHash = await PasswordHashService.hashPassword(testPassword);
  });

  setUp(() {
    mockUserRepository = _MockUserRepository();
    viewModel = LoginViewModel(userRepository: mockUserRepository);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('Initial State', () {
    test('Initial state is correct', () {
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.authenticatedUser, isNull);
    });
  });

  group('login', () {
    test('Successful login sets correct state', () async {
      // Setup mock user with verified email and valid password hash
      final testUser = User(
        id: 'test-user-id',
        email: testEmail,
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
        targetSleepDuration: 480,
        preferredUnitSystem: 'metric',
        language: 'en',
        hasSleepDisorder: false,
        takesSleepMedication: false,
        emailVerified: true,
        passwordHash: testPasswordHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockUserRepository.mockUser = testUser;

      final success = await viewModel.login(
        email: testEmail,
        password: testPassword,
      );

      expect(success, true);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.authenticatedUser, testUser);
      expect(mockUserRepository.currentUserId, testUser.id);
    });

    test('Empty email returns error', () async {
      final success = await viewModel.login(
        email: '',
        password: testPassword,
      );

      expect(success, false);
      expect(viewModel.errorMessage, contains('both email and password'));
      expect(viewModel.authenticatedUser, isNull);
    });

    test('Empty password returns error', () async {
      final success = await viewModel.login(
        email: testEmail,
        password: '',
      );

      expect(success, false);
      expect(viewModel.errorMessage, contains('both email and password'));
      expect(viewModel.authenticatedUser, isNull);
    });

    test('User not found returns error', () async {
      // Mock repository returns null (user doesn't exist)
      mockUserRepository.mockUser = null;

      final success = await viewModel.login(
        email: testEmail,
        password: testPassword,
      );

      expect(success, false);
      expect(viewModel.errorMessage, contains('No account found'));
      expect(viewModel.authenticatedUser, isNull);
    });

    test('User without password hash returns error', () async {
      final testUser = User(
        id: 'test-user-id',
        email: testEmail,
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
        targetSleepDuration: 480,
        preferredUnitSystem: 'metric',
        language: 'en',
        hasSleepDisorder: false,
        takesSleepMedication: false,
        emailVerified: true,
        passwordHash: null, // No password hash
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockUserRepository.mockUser = testUser;

      final success = await viewModel.login(
        email: testEmail,
        password: testPassword,
      );

      expect(success, false);
      expect(viewModel.errorMessage, contains('not set up correctly'));
      expect(viewModel.authenticatedUser, isNull);
    });

    test('Invalid password returns error', () async {
      final testUser = User(
        id: 'test-user-id',
        email: testEmail,
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
        targetSleepDuration: 480,
        preferredUnitSystem: 'metric',
        language: 'en',
        hasSleepDisorder: false,
        takesSleepMedication: false,
        emailVerified: true,
        passwordHash: testPasswordHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockUserRepository.mockUser = testUser;

      final success = await viewModel.login(
        email: testEmail,
        password: 'WrongPassword123',
      );

      expect(success, false);
      expect(viewModel.errorMessage, contains('Incorrect password'));
      expect(viewModel.authenticatedUser, isNull);
    });

    test('Email not verified returns error', () async {
      final testUser = User(
        id: 'test-user-id',
        email: testEmail,
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
        targetSleepDuration: 480,
        preferredUnitSystem: 'metric',
        language: 'en',
        hasSleepDisorder: false,
        takesSleepMedication: false,
        emailVerified: false, // Email not verified
        passwordHash: testPasswordHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockUserRepository.mockUser = testUser;

      final success = await viewModel.login(
        email: testEmail,
        password: testPassword,
      );

      expect(success, false);
      expect(viewModel.errorMessage, contains('verify your email'));
      expect(viewModel.authenticatedUser, isNull);
    });

    test('Loading state managed correctly during operation', () async {
      final testUser = User(
        id: 'test-user-id',
        email: testEmail,
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
        targetSleepDuration: 480,
        preferredUnitSystem: 'metric',
        language: 'en',
        hasSleepDisorder: false,
        takesSleepMedication: false,
        emailVerified: true,
        passwordHash: testPasswordHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockUserRepository.mockUser = testUser;

      final loadingStates = <bool>[];
      viewModel.addListener(() {
        loadingStates.add(viewModel.isLoading);
      });

      await viewModel.login(
        email: testEmail,
        password: testPassword,
      );

      expect(loadingStates, contains(true));
      expect(loadingStates.last, false);
    });

    test('Handles exception gracefully', () async {
      // Setup mock to throw exception
      mockUserRepository.shouldThrowException = true;

      final success = await viewModel.login(
        email: testEmail,
        password: testPassword,
      );

      expect(success, false);
      expect(viewModel.errorMessage, contains('Login failed'));
      expect(viewModel.authenticatedUser, isNull);
    });

    test('Notifies listeners during operation', () async {
      final testUser = User(
        id: 'test-user-id',
        email: testEmail,
        firstName: 'Test',
        lastName: 'User',
        birthDate: DateTime(1990, 1, 1),
        timezone: 'UTC',
        targetSleepDuration: 480,
        preferredUnitSystem: 'metric',
        language: 'en',
        hasSleepDisorder: false,
        takesSleepMedication: false,
        emailVerified: true,
        passwordHash: testPasswordHash,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      mockUserRepository.mockUser = testUser;

      var notifyCount = 0;
      viewModel.addListener(() => notifyCount++);

      await viewModel.login(
        email: testEmail,
        password: testPassword,
      );

      expect(notifyCount, greaterThan(0));
    });
  });

  group('clearError', () {
    test('Clears error message and notifies listeners', () async {
      // Set an error by attempting login with empty fields
      await viewModel.login(email: '', password: '');

      expect(viewModel.errorMessage, isNotNull);

      var notified = false;
      viewModel.addListener(() => notified = true);

      viewModel.clearError();

      expect(viewModel.errorMessage, isNull);
      expect(notified, true);
    });
  });
}

// Mock implementations

class _MockUserRepository implements UserRepository {
  User? mockUser;
  String? currentUserId;
  bool shouldThrowException = false;

  @override
  Future<User?> getUserByEmail(String email) async {
    if (shouldThrowException) {
      throw Exception('Test exception');
    }
    return mockUser;
  }

  @override
  Future<User?> getUserById(String userId) async {
    if (shouldThrowException) {
      throw Exception('Test exception');
    }
    return mockUser;
  }

  @override
  Future<void> setCurrentUserId(String userId) async {
    if (shouldThrowException) {
      throw Exception('Test exception');
    }
    currentUserId = userId;
  }

  @override
  Future<String?> getCurrentUserId() async {
    return currentUserId;
  }

  @override
  Future<void> saveUser(User user) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateUser(User user) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<User>> getAllUsers() async {
    throw UnimplementedError();
  }
}
