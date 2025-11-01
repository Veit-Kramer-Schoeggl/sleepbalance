import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'features/action_center/data/datasources/action_local_datasource.dart';
import 'features/action_center/data/repositories/action_repository_impl.dart';
import 'features/action_center/domain/repositories/action_repository.dart';
import 'features/night_review/data/datasources/sleep_record_local_datasource.dart';
import 'features/night_review/data/repositories/sleep_record_repository_impl.dart';
import 'features/night_review/domain/repositories/sleep_record_repository.dart';
import 'shared/screens/app/splash_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database (runs migrations if needed)
  final database = await DatabaseHelper.instance.database;

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
    );
  }
}
