import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:sleepbalance/features/habits_lab/presentation/viewmodels/habits_viewmodel.dart';
import 'package:sleepbalance/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';
import 'package:sleepbalance/modules/shared/domain/repositories/module_config_repository.dart';

import '../../../../shared/widgets/ui/acceptance_button.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';

/// Habits Lab screen for sleep habit tracking and experimentation.
///
/// Uses MVVM with Provider (HabitsViewModel) and persists module configs
/// via ModuleConfigRepository. Module UI labels/icons/descriptions come
/// from centralized ModuleMetadata.
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

    // Loading state
    if (viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator()
      );
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
      thumbVisibility: true,
      radius: const Radius.circular(10),
      thickness: 6,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        itemCount: modules.length,
        separatorBuilder: (_, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final module = modules[index];
          final isOn = viewModel.isModuleActive(module.id);

          final bool isImplemented = module.isAvailable;

          return InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (!isImplemented) {
                _showComingSoonDialog(context, module.displayName);
              }
            },
            child: Container(
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
                  Opacity(
                    opacity: isImplemented ? 1.0 : 0.45,
                    child: Icon(
                      module.icon,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title (from metadata)
                  Expanded(
                    child: Opacity(
                      opacity: isImplemented ? 1.0 : 0.45,
                        child: Text(
                          module.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ),
                  ),

                  // Checkbox – state from ViewModel
                  Opacity(
                    opacity: isImplemented ? 1.0 : 0.45,
                    child: Transform.scale(
                      scale: 1.2,
                      child: Checkbox(
                        value: isOn,
                        onChanged: (_) {
                          if (!isImplemented) {
                            _showComingSoonDialog(context, module.displayName);
                            return;
                          }
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
                  ),


                  const SizedBox(width: 8),
                  // Placeholder for module-specific configuration screens (not part of MVP).
                  Opacity(
                    opacity: isImplemented ? 1.0 : 0.45,
                    child: _GearButton(
                      onTap: () {
                        if (!isImplemented) {
                          _showComingSoonDialog(context, module.displayName);
                          return;
                        }
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
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  Opacity(
                    opacity: isImplemented ? 1.0 : 0.45,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isImplemented
                          ? () => _showModuleInfoDialog(context, module)
                          : null,
                      child: const _InfoButton(),
                    ),
                  ),



                ],
              ),
            ),
          ),
          );
        },
      ),
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: const Icon(Icons.info_outline, size: 18, color: Colors.white70),
    );
  }
}


void _showComingSoonDialog(BuildContext context, String moduleName) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF2B2F3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Coming soon', style: TextStyle(color: Colors.white)),
      content: Text(
        '"$moduleName" is coming soon.',
        style: const TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _showModuleInfoDialog(BuildContext context, ModuleMetadata module) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: const Color(0xFF2B2F3A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      title: Row(
        children: [
          Icon(module.icon, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${module.displayName} – Info',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),

      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // shortDescription
            if (module.shortDescription.trim().isNotEmpty) ...[
              Text(
                module.shortDescription,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // longDescription
            if (module.longDescription.trim().isNotEmpty)
              Text(
                module.longDescription,
                style: const TextStyle(color: Colors.white70),
              )
            else
              const Text(
                'This module is implemented as a basic prototype (MVP).',
                style: TextStyle(color: Colors.white70),
              ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
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