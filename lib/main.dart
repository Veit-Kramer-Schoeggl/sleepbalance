import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/database/database_helper.dart';
import 'features/action_center/data/datasources/action_local_datasource.dart';
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
import 'fitbit_test.dart';

void main() async {
  // Ensure Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

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
        // ViewModels
        // ============================================================================

        // Settings ViewModel - manages current user and settings state
        // Important: Registered AFTER UserRepository (its dependency)
        ChangeNotifierProvider<SettingsViewModel>(
          create: (context) => SettingsViewModel(
            repository: context.read<UserRepository>(),
          ),
        ),

        // Light Module ViewModel - manages light module state
        // Important: Registered AFTER LightRepository (its dependency)
        ChangeNotifierProvider<LightModuleViewModel>(
          create: (context) => LightModuleViewModel(
            repository: context.read<LightRepository>(),
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
      home: const SplashScreen(),
      routes: {
        '/fitbit': (context) => const FitbitTest(),
      }

    );
  }
}
