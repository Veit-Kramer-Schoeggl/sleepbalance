import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../../../modules/light/presentation/screens/light_config_standard_screen.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/date_navigation_header.dart';
import '../../../../shared/widgets/ui/checkbox_button.dart';
import '../../../../shared/widgets/ui/acceptance_button.dart';
import '../viewmodels/action_viewmodel.dart';
import 'package:sleepbalance/modules/shared/constants/module_metadata.dart';
import 'package:sleepbalance/shared/notifiers/action_refresh_notifier.dart';
import 'package:sleepbalance/modules/shared/domain/repositories/module_config_repository.dart';

/// Action Center screen for actionable sleep recommendations and tasks
///
/// Refactored to use MVVM + Provider pattern.
/// StatelessWidget that creates and provides ActionViewModel to child widgets.
/// Uses current user from SettingsViewModel for data operations.
class ActionScreen extends StatelessWidget {
  const ActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch SettingsViewModel to rebuild when user changes
    // This ensures ActionScreen updates after login/verification
    final settingsViewModel = context.watch<SettingsViewModel>();
    final currentUserId = settingsViewModel.currentUser?.id;

    // Handle case where user is not loaded
    if (currentUserId == null) {
      return BackgroundWrapper(
        imagePath: 'assets/images/main_background.png',
        overlayOpacity: 0.3,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Action Center',
                style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: const Center(
            child: Text(
              'No user logged in',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      );
    }

    // Create ActionViewModel with current user ID
    return ChangeNotifierProvider(
      create: (_) => ActionViewModel(
        repository: context.read(), // Reads ActionRepository from parent MultiProvider
        moduleConfigRepository: context.read<ModuleConfigRepository>(),
        userId: currentUserId, // Use actual user ID from SettingsViewModel
      )..loadActions(),
      child: const _ActionScreenContent(),
    );
  }
}

/// Private content widget that watches ActionViewModel
///
/// Rebuilds automatically when ViewModel state changes via notifyListeners().
class _ActionScreenContent extends StatefulWidget {
  const _ActionScreenContent();

  @override
  State<_ActionScreenContent> createState() => _ActionScreenContentState();
}

class _ActionScreenContentState extends State<_ActionScreenContent> {
  @override
  void initState() {
    super.initState();

    // Reload actions when Habits triggers a refresh
    actionRefreshTick.addListener(_onRefresh);
  }

  void _onRefresh() {
    if (!mounted) return;
    context.read<ActionViewModel>().loadActions();
  }

  @override
  void dispose() {
    actionRefreshTick.removeListener(_onRefresh);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ActionViewModel>();

    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Action Center',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Column(
          children: [
            // Date navigation header
            DateNavigationHeader(
              currentDate: viewModel.currentDate,
              onPreviousDay: () {
                viewModel.changeDate(
                  viewModel.currentDate.subtract(const Duration(days: 1)),
                );
              },
              onNextDay: () {
                viewModel.changeDate(
                  viewModel.currentDate.add(const Duration(days: 1)),
                );
              },
            ),

            // Error message display
            if (viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Main content area
            Expanded(
              child: viewModel.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : viewModel.actions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No actions for today',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              // TODO: Rework Action Center module configuration
                              // - Support multiple modules (not only Light)
                              // - Avoid hardcoded navigation to LightConfigStandardScreen
                              // - Show config options only for active/configurable modules
                              //
                              // Temporarily disabled for MVP delivery.
                              /*
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const LightConfigStandardScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Configure Light Module'),
                              ),
                              */
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            itemCount: viewModel.actions.length,
                            itemBuilder: (context, index) {
                              final action = viewModel.actions[index];

                              //get module metadata to keep UI consistent with Habits
                              final meta = getModuleMetadata(action.iconName);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CheckboxButton(
                                  text: meta.displayName,  //same name as in Habits
                                  icon: meta.icon,        //same icon as in Habits
                                  isChecked: action.isCompleted,
                                  onChanged: (_) =>
                                      viewModel.toggleAction(action.id),
                                ),
                              );
                            },
                          ),
                        ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24),
              child: AcceptanceButton(
                text: 'Complete Actions',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${viewModel.completedCount} of ${viewModel.actions.length} actions completed!',
                      ),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                width: double.infinity,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
