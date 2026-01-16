import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sleepbalance/features/night_review/presentation/viewmodels/night_review_viewmodel.dart';
import 'core/config/wearable_config.dart';
import 'core/database/database_helper.dart';
import 'core/wearables/data/datasources/fitbit_api_datasource.dart';
import 'core/wearables/data/datasources/wearable_credentials_local_datasource.dart';
import 'core/wearables/data/datasources/wearable_sync_record_local_datasource.dart';
import 'core/wearables/data/repositories/wearable_auth_repository_impl.dart';
import 'core/wearables/data/repositories/wearable_data_sync_repository_impl.dart';
import 'core/wearables/domain/repositories/wearable_auth_repository.dart';
import 'core/wearables/domain/repositories/wearable_data_sync_repository.dart';
import 'core/wearables/presentation/screens/wearable_connection_test_screen.dart';
import 'core/wearables/presentation/viewmodels/wearable_connection_viewmodel.dart';
import 'core/wearables/presentation/viewmodels/wearable_sync_viewmodel.dart';
import 'features/action_center/data/datasources/action_local_datasource.dart';
import 'features/auth/data/datasources/email_verification_local_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/repositories/email_verification_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/email_verification_repository.dart';
import 'features/auth/presentation/viewmodels/signup_viewmodel.dart';
import 'features/action_center/data/repositories/action_repository_impl.dart';
import 'features/action_center/domain/repositories/action_repository.dart';
import 'features/night_review/data/datasources/sleep_record_local_datasource.dart';
import 'features/night_review/data/repositories/sleep_record_repository_impl.dart';
import 'features/night_review/domain/repositories/sleep_record_repository.dart';
import 'features/settings/data/datasources/user_local_datasource.dart';
import 'features/settings/data/repositories/user_repository_impl.dart';
import 'features/settings/domain/repositories/user_repository.dart';
import 'features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'modules/light/data/datasources/light_module_local_datasource.dart';
import 'modules/light/data/repositories/light_module_repository_impl.dart';
import 'modules/light/domain/light_module.dart';
import 'modules/light/domain/repositories/light_repository.dart';
import 'modules/light/presentation/viewmodels/light_module_viewmodel.dart';
import 'modules/shared/data/datasources/module_config_local_datasource.dart';
import 'modules/shared/data/repositories/module_config_repository_impl.dart';
import 'modules/shared/domain/repositories/module_config_repository.dart';
import 'modules/shared/domain/services/module_registry.dart';
import 'shared/constants/database_constants.dart';
import 'shared/screens/app/splash_screen.dart';
import 'features/auth/presentation/screens/privacy_gate.dart';


void main() async {
  // Ensure Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // ============================================================================
  // Load Configuration
  // ============================================================================

  await WearableConfig.load();

  // ============================================================================
  // Register Modules
  // ============================================================================

  ModuleRegistry.register(LightModule());
  // TODO: Register other modules as they're implemented
  // ModuleRegistry.register(SportModule());
  // ModuleRegistry.register(MeditationModule());

  // Initialize database (runs migrations if needed)
  final database = await DatabaseHelper.instance.database;

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Set default user ID if not exists
  if (prefs.getString('current_user_id') == null) {
    final users = await database.query(
      TABLE_USERS,
      limit: 1,
    );
    if (users.isNotEmpty) {
      await prefs.setString('current_user_id', users.first[USERS_ID] as String);
    }
  }

  runApp(
    // MultiProvider wraps the app to provide dependencies to all widgets
    MultiProvider(
      providers: [
        // ============================================================================
        // Action Center - Data Layer
        // ============================================================================

        // Data sources layer - direct database access
        Provider<ActionLocalDataSource>(
          create: (_) => ActionLocalDataSource(database: database),
        ),

        // Repositories layer - abstracts data sources
        // Important: Register repositories AFTER their dependencies (data sources)
        Provider<ActionRepository>(
          create: (context) => ActionRepositoryImpl(
            dataSource: context.read<ActionLocalDataSource>(),
          ),
        ),

        // ============================================================================
        // Night Review - Data Layer
        // ============================================================================

        // Sleep Records DataSource
        Provider<SleepRecordLocalDataSource>(
          create: (_) => SleepRecordLocalDataSource(database: database),
        ),

        // Sleep Records Repository
        Provider<SleepRecordRepository>(
          create: (context) => SleepRecordRepositoryImpl(
            dataSource: context.read<SleepRecordLocalDataSource>(),
          ),
        ),

        // ============================================================================
        // Settings - User Data Layer
        // ============================================================================

        // SharedPreferences Provider
        Provider<SharedPreferences>(
          create: (_) => prefs,
        ),

        // User DataSource
        Provider<UserLocalDataSource>(
          create: (_) => UserLocalDataSource(database: database),
        ),

        // User Repository
        Provider<UserRepository>(
          create: (context) => UserRepositoryImpl(
            dataSource: context.read<UserLocalDataSource>(),
            prefs: context.read<SharedPreferences>(),
          ),
        ),

        // ============================================================================
        // Authentication - Data Layer
        // ============================================================================

        // Email Verification DataSource
        Provider<EmailVerificationLocalDataSource>(
          create: (_) => EmailVerificationLocalDataSource(
            DatabaseHelper.instance,
          ),
        ),

        // Email Verification Repository
        Provider<EmailVerificationRepository>(
          create: (context) => EmailVerificationRepositoryImpl(
            context.read<EmailVerificationLocalDataSource>(),
          ),
        ),

        // Auth Repository
        Provider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            context.read<UserRepository>(),
          ),
        ),

        // ============================================================================
        // Module Configuration Repository
        // ============================================================================

        // DataSource (needs database)
        Provider<ModuleConfigLocalDataSource>(
          create: (_) => ModuleConfigLocalDataSource(database: database),
        ),

        // Repository (needs datasource)
        Provider<ModuleConfigRepository>(
          create: (context) => ModuleConfigRepositoryImpl(
            dataSource: context.read<ModuleConfigLocalDataSource>(),
          ),
        ),

        // ============================================================================
        // Light Module - Data Layer
        // ============================================================================

        // Light Module DataSource
        Provider<LightModuleLocalDataSource>(
          create: (_) => LightModuleLocalDataSource(database: database),
        ),

        // Light Module Repository
        Provider<LightRepository>(
          create: (context) => LightModuleRepositoryImpl(
            dataSource: context.read<LightModuleLocalDataSource>(),
          ),
        ),

        // ============================================================================
        // Wearables - Data Layer
        // ============================================================================

        // Dio HTTP Client (for Fitbit API calls)
        Provider<Dio>(
          create: (_) => Dio(),
        ),

        // Wearable Credentials DataSource
        Provider<WearableCredentialsLocalDataSource>(
          create: (_) => WearableCredentialsLocalDataSource(database: database),
        ),

        // Wearable Sync Record DataSource
        Provider<WearableSyncRecordLocalDataSource>(
          create: (_) => WearableSyncRecordLocalDataSource(database: database),
        ),

        // Fitbit API DataSource
        Provider<FitbitApiDataSource>(
          create: (context) => FitbitApiDataSource(
            dio: context.read<Dio>(),
          ),
        ),

        // Wearable Auth Repository
        Provider<WearableAuthRepository>(
          create: (context) => WearableAuthRepositoryImpl(
            dataSource: context.read<WearableCredentialsLocalDataSource>(),
          ),
        ),

        // Wearable Data Sync Repository
        Provider<WearableDataSyncRepository>(
          create: (context) => WearableDataSyncRepositoryImpl(
            credentialsDataSource:
                context.read<WearableCredentialsLocalDataSource>(),
            syncRecordDataSource:
                context.read<WearableSyncRecordLocalDataSource>(),
            fitbitApiDataSource: context.read<FitbitApiDataSource>(),
            sleepRecordDataSource: context.read<SleepRecordLocalDataSource>(),
          ),
        ),

        // ============================================================================
        // ViewModels
        // ============================================================================

        // Settings ViewModel - manages current user and settings state
        // Important: Registered AFTER UserRepository (its dependency)
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(
            repository: context.read<UserRepository>(),
          ),
        ),

        ChangeNotifierProvider(
          create: (context) => NightReviewViewmodel(
            repository: context.read<SleepRecordRepository>(),
            userRepository: context.read<UserRepository>(),
          ),
        ),

        // Light Module ViewModel - manages light module state
        // Important: Registered AFTER LightRepository (its dependency)
        ChangeNotifierProvider<LightModuleViewModel>(
          create: (context) => LightModuleViewModel(
            repository: context.read<LightRepository>(),
          ),
        ),

        // Signup ViewModel - manages user registration flow
        // Important: Registered AFTER AuthRepository and EmailVerificationRepository
        ChangeNotifierProvider<SignupViewModel>(
          create: (context) => SignupViewModel(
            authRepository: context.read<AuthRepository>(),
            emailVerificationRepository: context.read<EmailVerificationRepository>(),
          ),
        ),

        // Wearable Connection ViewModel - manages wearable connections
        // Important: Registered AFTER WearableAuthRepository and SettingsViewModel
        // Note: userId is fetched dynamically in the screen
        ChangeNotifierProxyProvider<SettingsViewModel, WearableConnectionViewModel>(
          create: (context) => WearableConnectionViewModel(
            repository: context.read<WearableAuthRepository>(),
            userId: context.read<SettingsViewModel>().currentUser?.id ?? '',
          ),
          update: (context, settingsViewModel, previous) =>
              previous ??
              WearableConnectionViewModel(
                repository: context.read<WearableAuthRepository>(),
                userId: settingsViewModel.currentUser?.id ?? '',
              ),
        ),

        // Wearable Sync ViewModel - manages sleep data synchronization
        // Important: Registered AFTER WearableDataSyncRepository and SettingsViewModel
        ChangeNotifierProxyProvider<SettingsViewModel, WearableSyncViewModel>(
          create: (context) => WearableSyncViewModel(
            repository: context.read<WearableDataSyncRepository>(),
            userId: context.read<SettingsViewModel>().currentUser?.id ?? '',
          ),
          update: (context, settingsViewModel, previous) =>
              previous ??
              WearableSyncViewModel(
                repository: context.read<WearableDataSyncRepository>(),
                userId: settingsViewModel.currentUser?.id ?? '',
              ),
        ),
      ],
      child: const SleepBalanceApp(),
    ),
  );
}

class SleepBalanceApp extends StatelessWidget {
  const SleepBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SleepBalance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: PrivacyGate(
        child: const SplashScreen(),
      ),
      routes: {
        '/wearable-test': (context) => const WearableConnectionTestScreen(),
        // TODO: Move to proper settings screen when implementing full wearables UI
      },
    );
  }
}
