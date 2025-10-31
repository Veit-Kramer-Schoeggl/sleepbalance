import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleepbalance/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsViewModel(
        context: context
      ),
      child: const _SettingsScreenContent(),
    );
  }
}

class _SettingsScreenContent extends StatelessWidget {
  const _SettingsScreenContent();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('App Settings', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,

          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.settings,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              const Text(
                'App Settings',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure your app preferences',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              Padding(padding: EdgeInsets.all(16), child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(padding: EdgeInsets.all(16)),
                    ElevatedButton.icon(
                      onPressed: viewModel.onChangeTimeZone,
                      label: const Text("Timezone"),
                      icon: const Icon(Icons.access_time),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft, // optional: left-align content
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: viewModel.onChangeUserProfile,
                      label: const Text("Userprofile"),
                      icon: Icon(Icons.person),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft, // optional: left-align content
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: viewModel.onChangeDateTimeFormat,
                      label: const Text("Date/Time Format"),
                      icon: const Icon(Icons.date_range),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft, // optional: left-align content
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: viewModel.onChangeUnits,
                      label: const Text("Units (Imperial/Metric)"),
                      icon: const Icon(Icons.straighten),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft, // optional: left-align content
                      ),
                    ),
                  ],
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}