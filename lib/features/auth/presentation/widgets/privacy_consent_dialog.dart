import 'package:flutter/material.dart';

/// PrivacyConsentDialog
/// A modal dialog that requests explicit user consent for the app's
/// data privacy policy.

class PrivacyConsentDialog extends StatefulWidget {
  const PrivacyConsentDialog({super.key});

  @override
  State<PrivacyConsentDialog> createState() => _PrivacyConsentDialogState();
}

class _PrivacyConsentDialogState extends State<PrivacyConsentDialog> {
  bool checked = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Data Privacy'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'To use this app you must accept the privacy policy. '
                  'We process your data according to our privacy terms.',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: checked,
                  onChanged: (v) => setState(() => checked = v ?? false),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('I have read and accept the privacy policy.'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: checked ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Accept'),
        ),
      ],
    );
  }
}
