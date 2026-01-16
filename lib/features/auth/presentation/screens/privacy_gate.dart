import 'package:flutter/material.dart';
import '../viewmodels//privacy_consent_service.dart';
import '../widgets/privacy_consent_dialog.dart';

/// PrivacyGate
/// A lightweight pre-authentication gate that ensures the user has accepted the
/// app's data privacy policy before continuing into the application.

class PrivacyGate extends StatefulWidget {
  final Widget child;
  const PrivacyGate({super.key, required this.child});


  @override
  State<PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<PrivacyGate> {
  final _service = PrivacyConsentService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final accepted = await _service.hasAccepted();
    if (!mounted) return;

    if (!accepted) {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PrivacyConsentDialog(),
      );

      if (ok == true) {
        await _service.accept();
      }
    }

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return widget.child;
  }
}
