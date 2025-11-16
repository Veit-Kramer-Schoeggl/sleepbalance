import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../domain/enums/wearable_provider.dart';
import '../viewmodels/wearable_connection_viewmodel.dart';

/// Wearable Connection Test Screen
///
/// Temporary test screen for validating Fitbit OAuth integration.
/// Shows connection status, last sync time, and token expiration.
///
/// Features:
/// - Connect/Disconnect buttons for Fitbit
/// - Display connection status
/// - Show token expiration details
/// - Error handling with user feedback
///
/// TODO: This is a temporary test screen. Move to proper Settings UI later.
class WearableConnectionTestScreen extends StatefulWidget {
  const WearableConnectionTestScreen({super.key});

  @override
  State<WearableConnectionTestScreen> createState() =>
      _WearableConnectionTestScreenState();
}

class _WearableConnectionTestScreenState
    extends State<WearableConnectionTestScreen> {
  @override
  void initState() {
    super.initState();
    // Load connections after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsViewModel = context.read<SettingsViewModel>();
      final userId = settingsViewModel.currentUser?.id;
      if (userId != null) {
        final viewModel = Provider.of<WearableConnectionViewModel>(
          context,
          listen: false,
        );
        viewModel.loadConnections();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wearable Connections'),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<WearableConnectionViewModel>(
        builder: (context, viewModel, child) {
          // Loading state
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (viewModel.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      viewModel.errorMessage ?? 'Unknown error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.clearError,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            );
          }

          // Main content
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              const Text(
                'Connect your wearable devices to sync sleep data',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Fitbit Connection Card
              _buildFitbitCard(context, viewModel),

              const SizedBox(height: 16),

              // Future providers placeholder
              _buildPlaceholderCard('Apple Health', Icons.favorite),
              const SizedBox(height: 16),
              _buildPlaceholderCard('Google Fit', Icons.fitness_center),
              const SizedBox(height: 16),
              _buildPlaceholderCard('Garmin', Icons.watch),
            ],
          );
        },
      ),
    );
  }

  /// Build Fitbit connection card
  Widget _buildFitbitCard(
    BuildContext context,
    WearableConnectionViewModel viewModel,
  ) {
    final isConnected = viewModel.isConnected(WearableProvider.fitbit);
    final connection = viewModel.getConnection(WearableProvider.fitbit);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fitbit',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Sleep tracking & heart rate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                // Connection status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isConnected ? Colors.green : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConnected ? 'Connected' : 'Not Connected',
                    style: TextStyle(
                      color: isConnected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Connection details (if connected)
            if (isConnected && connection != null) ...[
              _buildDetailRow(
                'Connected since',
                _formatDateTime(connection.connectedAt),
              ),
              _buildDetailRow(
                'Last sync',
                connection.lastSyncAt != null
                    ? _formatDateTime(connection.lastSyncAt!)
                    : 'Never',
              ),
              _buildDetailRow(
                'Token expires',
                connection.tokenExpiresAt != null
                    ? _formatDateTime(connection.tokenExpiresAt!)
                    : 'Unknown',
              ),
              _buildDetailRow(
                'Token status',
                connection.isTokenExpired()
                    ? 'EXPIRED (needs refresh)'
                    : 'Valid',
                valueColor:
                    connection.isTokenExpired() ? Colors.red : Colors.green,
              ),
              const SizedBox(height: 12),
            ],

            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final settingsViewModel = context.read<SettingsViewModel>();
                  final userId = settingsViewModel.currentUser?.id;

                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User not found. Please restart the app.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (isConnected) {
                    // Disconnect
                    await viewModel.disconnectProvider(WearableProvider.fitbit);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitbit disconnected successfully'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  } else {
                    // Connect
                    await viewModel.connectFitbit();
                    if (context.mounted && !viewModel.hasError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fitbit connected successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  isConnected ? 'Disconnect Fitbit' : 'Connect Fitbit',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a detail row (label: value)
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Build placeholder card for future providers
  Widget _buildPlaceholderCard(String name, IconData icon) {
    return Card(
      elevation: 2,
      color: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.grey,
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Not Available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
