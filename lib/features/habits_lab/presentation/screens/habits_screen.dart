import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleepbalance/features/settings/presentation/viewmodels/settings_viewmodel.dart';

import 'package:sleepbalance/modules/shared/domain/repositories/module_config_repository.dart';
import 'package:sleepbalance/features/habits_lab/presentation/viewmodels/habits_viewmodel.dart';

import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/acceptance_button.dart';

// TODO: Remove fitbit_test import - file has been removed from version control
// import 'package:sleepbalance/fitbit_test.dart';

// TODO: Import module metadata when implementing proper architecture
// import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';

// TODO: Import ViewModel and Provider when implementing MVVM pattern
// import 'package:provider/provider.dart';
// import '../viewmodels/habits_viewmodel.dart';

/// Habits Lab screen for sleep habit tracking and experimentation
///
/// TODO: Refactor to use MVVM pattern with Provider (see REPORT.md)
/// Current implementation uses local state - needs to be connected to:
/// - HabitsViewModel (to be created)
/// - ModuleConfigRepository (for database persistence)
/// - ModuleMetadata (for centralized module information)
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final settingsViewModel = context.watch<SettingsViewModel>();
    final user = settingsViewModel.currentUser;

    if (user == null) {
      return BackgroundWrapper(
        imagePath: 'assets/images/main_background.png',
        overlayOpacity: 0.3,
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final userId = user.id;

    final repository = context.read<ModuleConfigRepository>();

    return ChangeNotifierProvider(
      create: (_) => HabitsViewModel(
          repository: repository,
      )..loadModules(userId),
      child: _HabitsScreenContent(userId: userId),
    );
  }
}

class _HabitsScreenContent extends StatelessWidget {
  final String userId;

  const _HabitsScreenContent({required this.userId});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HabitsViewModel>();

    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Habits Lab',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.science,
                      size: 80,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Habits Lab',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Track and experiment with sleep habits',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(color: Colors.white24, height: 1),
            ),
            const SizedBox(height: 12),

            // Main content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _ModulesList(userId: userId),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: AcceptanceButton(
                text: 'Save Habits',
                onPressed: () {
                  final viewModel = context.read<HabitsViewModel>();

                  viewModel.saveModuleConfigs(userId);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Habits saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },

                width: double.infinity,
              ),
            ),

            // See: WEARABLES_INTEGRATION_REPORT.md for implementation plan
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/wearable-test');
              },
              child: const Text('Fitbit verbinden'),
            ),

          ],
        ),
      ),
    );
  }
}

/// List of modules backed by HabitsViewModel.
/// No local state, all state comes from the ViewModel + database.
class _ModulesList extends StatelessWidget {
  final String userId;

  const _ModulesList({required this.userId});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HabitsViewModel>();
    final controller = ScrollController();

    // Loading state
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state
    if (viewModel.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              viewModel.errorMessage!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => viewModel.loadModules(userId),
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    // Use central module metadata instead of hardcoded list
    final modules = viewModel.availableModules;

    if (modules.isEmpty) {
      return const Center(
        child: Text(
          'No modules available yet.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Scrollbar(
      controller: controller,
      thumbVisibility: true,
      radius: const Radius.circular(10),
      thickness: 6,
      child: ListView.separated(
        controller: controller,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        itemCount: modules.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final module = modules[index];
          final isOn = viewModel.isModuleActive(module.id);

          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  // Left icon (from metadata)
                  Icon(
                    module.icon,
                    size: 22,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),

                  // Title (from metadata)
                  Expanded(
                    child: Text(
                      module.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  // Checkbox – state from ViewModel
                  Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: isOn,
                      onChanged: (_) {
                        viewModel.toggleModule(userId, module.id);
                      },
                      activeColor: Theme.of(context).colorScheme.primary,
                      checkColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.7),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Settings button – placeholder for future config screens
                  // TODO: Navigate to module-specific config screen
                  // Should call: viewModel.openModuleConfig(context, userId, moduleId)

                  _GearButton(onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: const Color(0xFF2B2F3A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: const Text(
                          'Settings',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: Text(
                          '"${module.displayName}" settings are coming soon.',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'OK',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Small "settings" button with pill look
class _GearButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GearButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
        ),
        child: const Icon(Icons.settings, size: 18, color: Colors.white70),
      ),
    );
  }
}