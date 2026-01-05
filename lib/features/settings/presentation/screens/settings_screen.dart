import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleepbalance/features/settings/domain/models/user.dart';
import 'package:sleepbalance/features/settings/presentation/viewmodels/settings_viewmodel.dart';
import 'package:sleepbalance/features/settings/presentation/widgets/sleep_target_slider.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';

/// Settings Screen - Main settings overview
///
/// Uses the global SettingsViewModel from main.dart Provider tree.
/// Navigation is handled locally within this screen.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  bool _saving = false;
  int? _sleepTarget;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Reload user every time Settings screen appears
    // This ensures we have the latest user data after login/verification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsViewModel>().loadCurrentUser();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    final user = context.watch<SettingsViewModel>().currentUser;
    _sleepTarget = user?.targetSleepDuration;

    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SettingsViewModel>();

    if (viewModel.isLoading && !_saving) {
      return Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(child: Text("Fehler: ${viewModel.errorMessage}"));
    }

    final User? user = viewModel.currentUser;
    _saving = false;

    final profile = _profileTile(user);
    final middle = _middleSection(viewModel);
    final logout = _logoutListTile(viewModel);

    final settings = _buildSettings(profile, middle, logout);

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
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: settings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSettings(ListTile top, List<Widget> middle, ListTile? bottom) {
    var settings = <Widget>[
      top,
      const SizedBox(height: 64),
    ];

    for (var widget in middle) {
      settings.add(widget);
    }

    if (bottom != null) {
      settings.add(const SizedBox(height: 64));
      settings.add(bottom);
    }

    return settings;
  }

  List<Widget> _middleSection(SettingsViewModel viewModel) {
    final user = viewModel.currentUser;

    final targetDuration = _settingsItemTile(
        Icon(Icons.bedtime),
        "Schlafziel",
        "${_sleepTarget ?? 360} Minuten (${((_sleepTarget ?? 360) / 60).toStringAsFixed(1)} h)",
        enabled: user != null,
        action: () => showDialog(context: context, builder: (context) => _sleepTargetDialog(context, viewModel))
    );

    final languages = _settingsItemTile(
        Icon(Icons.language),
        "Sprachen",
        user?.language?.toUpperCase() ?? "EN",
        enabled: user != null,
        action: () => showDialog(context: context, builder: (context) => _languageDialog(context, viewModel))
    );

    final units = _settingsItemTile(
        Icon(Icons.straighten),
        "Einheiten",
        user?.preferredUnitSystem ?? "",
        enabled: user != null,
        trailing: Switch(
            value: user?.preferredUnitSystem == 'metric',
            onChanged: user != null ? (isMetric) => setState(() {
              _saving = true;
              viewModel.updateUnitSystem(isMetric ? 'metric' : 'imperial');
            }) : null
        )
    );


    final spacer = const SizedBox(height: 16);

    return <Widget> [
      targetDuration,
      spacer,
      languages,
      spacer,
      units
    ];
  }

  ListTile _profileTile(User? user) {
    final firstLetter = user?.firstName.characters.elementAt(0);

    return ListTile(
      leading: CircleAvatar(
          child: firstLetter != null
              ? Text(firstLetter!)
              : const Icon(Icons.person)
      ),
      enabled: user != null,
      title: Text(user?.firstName ?? "Gast", style: TextStyle(color: Colors.white)),
      subtitle: Text(user?.email ?? "Nicht Eingeloggt", style: TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.settings,
        size: 40,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide( color: Colors.white.withOpacity(0.12))
      ),
      tileColor: Colors.white.withOpacity(0.06),
      onTap: () => Navigator.of(context).pushNamed('/profile'),
    );
  }

  ListTile _settingsItemTile(
    Icon icon,
    String title,
    String subtitle,
    {
      bool enabled = true,
      Function? action,
      Widget? trailing
    }) {

    trailing ??= Icon(
      Icons.chevron_right,
      size: 30,
      color: enabled ? Colors.white : Colors.white24,
    );

    return ListTile(
      leading: icon,
      iconColor: Colors.white,
      title: Text(title, style: TextStyle(color: enabled ? Colors.white : Colors.white24)),
      subtitle: Text(subtitle, style: TextStyle(color: enabled ? Colors.white : Colors.white24)),
      trailing: trailing,
      enabled: enabled,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide( color: Colors.white.withOpacity(0.12))
      ),
      tileColor: Colors.white.withOpacity(0.06),
      onTap: () => {
        if (action != null) {
          action()
        }
      }
    );
  }

  ListTile? _logoutListTile(SettingsViewModel viewModel) {
    if (viewModel.currentUser == null) {
      return null;
    }

    return ListTile(
      leading: Icon(Icons.logout),
      iconColor: Colors.white,
      title: Text("Logout", style: TextStyle(color: Colors.white)),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: Colors.red.withOpacity(0.64))
      ),
      tileColor: Colors.red.withOpacity(0.32),
      onTap: () => viewModel.logout(),
    );
  }

  Dialog _languageDialog(BuildContext context, SettingsViewModel viewModel) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white12)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "Sprache auswählen",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),

          ListTile(
            title: const Text("English"),
            onTap: () {
              _saving = true;
              viewModel.updateLanguage("en");
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text("Deutsch"),
            onTap: () {
              _saving = true;
              viewModel.updateLanguage("de");
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Dialog _sleepTargetDialog(BuildContext context, SettingsViewModel viewModel) {
    var tempTarget = _sleepTarget;

    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white12)
      ),
      child: StatefulBuilder(
        builder: (context, setDialogState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Schlafziel Einstellen",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),

              Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: sleepTargetSlider(tempTarget, (value) => setDialogState(() {
                  tempTarget = value.toInt();
                }), textColor: Colors.black),
              ),
              Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                          child: MaterialButton(
                              child: Text("Cancel"),
                              onPressed: () => Navigator.of(context).pop()
                          ),
                      ),
                      Expanded(
                        child: MaterialButton(
                          child: Text("Save"),
                          onPressed: () async {
                            _saving = true;
                            _sleepTarget = tempTarget;
                            await viewModel.updateSleepTargets(targetSleepDuration: tempTarget);

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                        )
                      )
                    ],
                  )
              )
            ],
          );
        },
      )
    );
  }
}