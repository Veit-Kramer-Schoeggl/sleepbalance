import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../../../shared/widgets/ui/date_navigation_header.dart';
import '../../../../shared/widgets/ui/checkbox_button.dart';
import '../../../../shared/widgets/ui/acceptance_button.dart';
import '../viewmodels/action_viewmodel.dart';

/// Action Center screen for actionable sleep recommendations and tasks
///
/// Refactored to use MVVM + Provider pattern.
/// StatelessWidget that creates and provides ActionViewModel to child widgets.
class ActionScreen extends StatelessWidget {
  const ActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ActionViewModel(
        repository: context.read(), // Reads ActionRepository from parent MultiProvider
        userId: 'temp-user-id', // TODO: Replace with actual user ID from auth
      )..loadActions(),
      child: const _ActionScreenContent(),
    );
  }
}

/// Private content widget that watches ActionViewModel
///
/// Rebuilds automatically when ViewModel state changes via notifyListeners().
class _ActionScreenContent extends StatelessWidget {
  const _ActionScreenContent();

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
                              ElevatedButton(
                                onPressed: viewModel.addDefaultActions,
                                child: const Text('Add Default Actions'),
                              ),
                            ],
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListView.builder(
                            itemCount: viewModel.actions.length,
                            itemBuilder: (context, index) {
                              final action = viewModel.actions[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: CheckboxButton(
                                  text: action.title,
                                  icon: action.icon,
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
