import 'package:flutter/material.dart';
import 'package:fitbitter/fitbitter.dart';
import 'fitbit_secrets.dart';

class FitbitTest extends StatefulWidget {
  const FitbitTest({super.key});
  @override
  State<FitbitTest> createState() => _FitbitTestState();
}

class _FitbitTestState extends State<FitbitTest> {
  String status = 'Nicht verbunden';

  Future<void> _connect() async {
    try {
      final creds = await FitbitConnector.authorize(
        clientID: FitbitSecrets.clientId,
        clientSecret: FitbitSecrets.clientSecret,
        redirectUri: FitbitSecrets.redirectUri,
        callbackUrlScheme: FitbitSecrets.callbackScheme,
      );
      setState(() =>
      status = creds == null ? 'Abgebrochen' : 'Autorisiert: ${creds.userID}');
    } catch (e) {
      setState(() => status = 'Fehler: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fitbit Login Test')),
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(status),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _connect,
          child: const Text('Mit Fitbit verbinden'),
        ),
      ]),
    ),
  );
}
