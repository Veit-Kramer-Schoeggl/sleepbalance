import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleepbalance/modules/light/presentation/viewmodels/light_module_viewmodel.dart';
import 'package:sleepbalance/features/settings/presentation/viewmodels/settings_viewmodel.dart';

class LightConfigStandardScreen extends StatefulWidget {
  const LightConfigStandardScreen({super.key});

  @override
  State<LightConfigStandardScreen> createState() => _LightConfigStandardScreenState();
}

class _LightConfigStandardScreenState extends State<LightConfigStandardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsViewModel = context.read<SettingsViewModel>();
      final userId = settingsViewModel.currentUser?.id;
      if (userId != null) {
        context.read<LightModuleViewModel>().loadConfig(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Light Therapy')),
      body: Consumer<LightModuleViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.hasError) {
            return Center(child: Text('Error: ${viewModel.errorMessage}'));
          }

          final config = viewModel.lightConfig;
          if (config == null) {
            return const Center(child: Text('No configuration loaded'));
          }

          return ListView(
            children: [
              // Enable/Disable Switch
              SwitchListTile(
                title: const Text('Enable Light Therapy'),
                value: viewModel.isEnabled,
                onChanged: (value) async {
                  final userId = context.read<SettingsViewModel>().currentUser?.id;
                  if (userId != null) {
                    await viewModel.toggleModule(userId);
                  }
                },
              ),

              if (viewModel.isEnabled) ...[
                const Divider(),

                // Light Type Dropdown
                ListTile(
                  title: const Text('Light Type'),
                  trailing: DropdownButton<String>(
                    value: config.lightType,
                    items: const [
                      DropdownMenuItem(value: 'natural_sunlight', child: Text('Natural Sunlight')),
                      DropdownMenuItem(value: 'light_box', child: Text('Light Box (10,000 lux)')),
                      DropdownMenuItem(value: 'blue_light', child: Text('Blue Light Therapy')),
                      DropdownMenuItem(value: 'red_light', child: Text('Red Light Therapy')),
                    ],
                    onChanged: (value) => _updateConfig(lightType: value),
                  ),
                ),

                // Target Time Picker
                ListTile(
                  title: const Text('Target Time'),
                  subtitle: Text(config.targetTime ?? '07:30'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: _parseTime(config.targetTime ?? '07:30'),
                    );
                    if (time != null) {
                      _updateConfig(targetTime: '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
                    }
                  },
                ),

                // Duration Slider
                ListTile(
                  title: Text('Duration: ${config.targetDurationMinutes ?? 30} minutes'),
                  subtitle: Slider(
                    value: (config.targetDurationMinutes ?? 30).toDouble(),
                    min: 15,
                    max: 60,
                    divisions: 9,
                    label: '${config.targetDurationMinutes ?? 30} min',
                    onChanged: (value) => _updateConfig(duration: value.toInt()),
                  ),
                ),

                const Divider(),
                ListTile(
                  title: Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
                ),

                // Morning Reminder
                SwitchListTile(
                  title: const Text('Morning Reminder'),
                  subtitle: Text(config.morningReminderTime),
                  value: config.morningReminderEnabled,
                  onChanged: (value) => _updateConfig(morningReminderEnabled: value),
                ),

                // Evening Dim Reminder
                SwitchListTile(
                  title: const Text('Evening Dim Reminder'),
                  subtitle: Text(config.eveningDimTime),
                  value: config.eveningDimReminderEnabled,
                  onChanged: (value) => _updateConfig(eveningDimEnabled: value),
                ),

                // Blue Blocker Reminder
                SwitchListTile(
                  title: const Text('Blue Blocker Reminder'),
                  subtitle: Text(config.blueBlockerTime),
                  value: config.blueBlockerReminderEnabled,
                  onChanged: (value) => _updateConfig(blueBlockerEnabled: value),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  void _updateConfig({
    String? targetTime,
    int? duration,
    String? lightType,
    bool? morningReminderEnabled,
    bool? eveningDimEnabled,
    bool? blueBlockerEnabled,
  }) async {
    final viewModel = context.read<LightModuleViewModel>();
    final userId = context.read<SettingsViewModel>().currentUser?.id;

    if (viewModel.lightConfig == null || userId == null) return;

    final updatedConfig = viewModel.lightConfig!.copyWith(
      targetTime: targetTime,
      targetDurationMinutes: duration,
      lightType: lightType,
      morningReminderEnabled: morningReminderEnabled,
      eveningDimReminderEnabled: eveningDimEnabled,
      blueBlockerReminderEnabled: blueBlockerEnabled,
    );

    await viewModel.saveConfig(userId, updatedConfig);
  }
}
