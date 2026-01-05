import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sleepbalance/features/settings/presentation/widgets/sleep_target_slider.dart';

import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../viewmodels/settings_viewmodel.dart';
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  DateTime? _selectedBirthDate;
  int? _targetSleepMinutes;
  bool _hasSleepDisorder = false;
  bool _takesSleepMedication = false;

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) return;

    final user = context.read<SettingsViewModel>().currentUser;
    if (user != null) {
      _firstNameController.text = user.firstName;
      _lastNameController.text = user.lastName;
      _emailController.text = user.email;
      _selectedBirthDate = user.birthDate;
      _targetSleepMinutes = user.targetSleepDuration;
      _hasSleepDisorder = user.hasSleepDisorder;
      _takesSleepMedication = user.takesSleepMedication;
    }

    _initialized = true;
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    var user = context.read<SettingsViewModel>().currentUser;

    if (user == null) {
      return;
    }

    final updatedUser = user.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        birthDate: _selectedBirthDate ?? DateTime.now(),
        targetSleepDuration: _targetSleepMinutes,
        hasSleepDisorder: _hasSleepDisorder,
        takesSleepMedication: _takesSleepMedication,
    );

    context.read<SettingsViewModel>().updateUserProfile(updatedUser);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil gespeichert')),
    );
  }

  Widget _datePicker(BuildContext context) {
    final formatted = _selectedBirthDate == null
        ? 'Bitte auswählen'
        : DateFormat('dd.MM.yyyy').format(_selectedBirthDate!);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final now = DateTime.now();
        final initialDate = _selectedBirthDate ??
            DateTime(now.year - 20, now.month, now.day); // nicer default

        final picked = await showDatePicker(
          context: context,
          initialDate: initialDate,
          firstDate: DateTime(1900),
          lastDate: now,
        );

        if (picked != null) {
          setState(() {
            _selectedBirthDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Geburtsdatum',
          labelStyle: TextStyle(color: Colors.white),
          hintText: 'TT.MM.JJJJ',
          border: OutlineInputBorder(),
          suffixIcon: Icon(Icons.calendar_today, color: Colors.white),
        ),
        child: Text(formatted, style: TextStyle(color: Colors.white)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Profil bearbeiten', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Consumer<SettingsViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.currentUser == null) {
              return const Center(child: Text('Kein User geladen'));
            }

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'Vorname',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Pflichtfeld' : null,
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nachname',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      validator: (value) =>
                      value == null || value.isEmpty ? 'Pflichtfeld' : null,
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'E-Mail',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Pflichtfeld';
                        }
                        if (!value.contains('@')) {
                          return 'Ungültige E-Mail-Adresse';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    _datePicker(context),
                    const SizedBox(height: 24),

                    sleepTargetSlider(_targetSleepMinutes, (value) => setState(() {
                      _targetSleepMinutes = value.toInt();
                    })),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      value: _hasSleepDisorder,
                      title: const Text('Schlafstörung vorhanden', style: TextStyle(color: Colors.white)),
                      onChanged: (value) {
                        setState(() {
                          _hasSleepDisorder = value ?? false;
                        });
                      },
                    ),

                    SwitchListTile(
                      value: _takesSleepMedication,
                      title: const Text('Nimmt Schlafmedikamente', style: TextStyle(color: Colors.white)),
                      onChanged: (value) {
                        setState(() {
                          _takesSleepMedication = value ?? false;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    FloatingActionButton(
                      onPressed: _saveProfile,
                      child: const Icon(Icons.save),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
