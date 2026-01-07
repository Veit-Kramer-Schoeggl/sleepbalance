import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  final exp = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

  DateTime? _selectedBirthDate;
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
      _hasSleepDisorder = user.hasSleepDisorder;
      _takesSleepMedication = user.takesSleepMedication;
    }

    _initialized = true;
  }

  void setupListeners() {
    _firstNameController.removeListener(_saveProfile);
    _lastNameController.removeListener(_saveProfile);
    _emailController.removeListener(_saveProfile);

    _firstNameController.addListener(_saveProfile);
    _lastNameController.addListener(_saveProfile);
    _emailController.addListener(_saveProfile);
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
        hasSleepDisorder: _hasSleepDisorder,
        takesSleepMedication: _takesSleepMedication,
    );

    context.read<SettingsViewModel>().updateUserProfile(updatedUser);
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
            _saveProfile();
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

  bool emailValid() {
    return exp.hasMatch(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    setupListeners();

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

                        if (!emailValid()) {
                          return 'Invalid email address';
                        }
                        return null;
                      },
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 24),

                    _datePicker(context),
                    const SizedBox(height: 24),

                    SwitchListTile(
                      value: _hasSleepDisorder,
                      title: const Text('Schlafstörung vorhanden', style: TextStyle(color: Colors.white)),
                      onChanged: (value) {
                        setState(() {
                          _hasSleepDisorder = value ?? false;
                        });

                        _saveProfile();
                      },
                    ),

                    SwitchListTile(
                      value: _takesSleepMedication,
                      title: const Text('Nimmt Schlafmedikamente', style: TextStyle(color: Colors.white)),
                      onChanged: (value) {
                        setState(() {
                          _takesSleepMedication = value ?? false;
                        });

                        _saveProfile();
                      },
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();

    super.dispose();
  }
}
