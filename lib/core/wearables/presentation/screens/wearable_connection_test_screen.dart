import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../features/settings/presentation/viewmodels/settings_viewmodel.dart';
import '../../../../shared/widgets/ui/background_wrapper.dart';
import '../../domain/enums/wearable_provider.dart';
import '../viewmodels/wearable_connection_viewmodel.dart';
import '../viewmodels/wearable_sync_viewmodel.dart';

/// Wearable Connection Test Screen
///
/// Test screen for validating Fitbit OAuth integration and data sync.
/// Uses the app's default background styling from habits_lab.
///
/// Features:
/// - Connect/Disconnect buttons for Fitbit
/// - Display connection status
/// - Show token expiration details
/// - Sync sleep data with loading/success/error states
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
    // Load connections and sync state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsViewModel = context.read<SettingsViewModel>();
      final userId = settingsViewModel.currentUser?.id;
      if (userId != null) {
        // Load wearable connections
        Provider.of<WearableConnectionViewModel>(
          context,
          listen: false,
        ).loadConnections();

        // Load last sync date
        Provider.of<WearableSyncViewModel>(
          context,
          listen: false,
        ).loadLastSyncDate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      imagePath: 'assets/images/main_background.png',
      overlayOpacity: 0.3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Wearable Connections',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Consumer<WearableConnectionViewModel>(
          builder: (context, viewModel, child) {
            // Loading state
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
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
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        viewModel.errorMessage ?? 'Unknown error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: viewModel.clearError,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        foregroundColor: Colors.white,
                      ),
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
                const Icon(
                  Icons.watch,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Connect your wearable devices to sync sleep data',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Fitbit Connection Card
                _buildFitbitCard(context, viewModel),

                const SizedBox(height: 16),

                // Future providers placeholder
                _buildPlaceholderCard('Apple Health', Icons.favorite),
                const SizedBox(height: 12),
                _buildPlaceholderCard('Google Fit', Icons.fitness_center),
                const SizedBox(height: 12),
                _buildPlaceholderCard('Garmin', Icons.watch),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Build Fitbit connection card with app styling
  Widget _buildFitbitCard(
    BuildContext context,
    WearableConnectionViewModel viewModel,
  ) {
    final isConnected = viewModel.isConnected(WearableProvider.fitbit);
    final connection = viewModel.getConnection(WearableProvider.fitbit);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 28,
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Sleep tracking & heart rate',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white60,
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
                    color: isConnected
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isConnected
                          ? Colors.green.withValues(alpha: 0.5)
                          : Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    isConnected ? 'Connected' : 'Not Connected',
                    style: TextStyle(
                      color: isConnected ? Colors.greenAccent : Colors.white60,
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
                valueColor: connection.isTokenExpired()
                    ? Colors.redAccent
                    : Colors.greenAccent,
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
                  backgroundColor: isConnected
                      ? Colors.red.withValues(alpha: 0.8)
                      : Colors.blue.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isConnected ? 'Disconnect Fitbit' : 'Connect Fitbit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Sync section (only show when connected)
            if (isConnected) ...[
              const SizedBox(height: 20),
              Divider(color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 12),
              _buildSyncSection(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Build sync section with button and status
  Widget _buildSyncSection(BuildContext context) {
    return Consumer<WearableSyncViewModel>(
      builder: (context, syncViewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            const Text(
              'Sync Sleep Data',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Last sync info
            if (syncViewModel.lastSyncDate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Last synced: ${_formatDateTime(syncViewModel.lastSyncDate!)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ),

            // Sync button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: syncViewModel.isSyncing
                    ? null
                    : () => syncViewModel.syncRecentData(days: 7),
                icon: syncViewModel.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  syncViewModel.isSyncing ? 'Syncing...' : 'Sync Last 7 Days',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.green.withValues(alpha: 0.4),
                  disabledForegroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Success message
            if (syncViewModel.isSuccess && syncViewModel.lastSyncResult != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Synced ${syncViewModel.lastSyncResult!.recordsInserted} new, '
                          '${syncViewModel.lastSyncResult!.recordsUpdated} updated',
                          style: const TextStyle(color: Colors.greenAccent),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white60,
                        ),
                        onPressed: syncViewModel.clearSuccess,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),

            // Error message
            if (syncViewModel.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          syncViewModel.errorMessage ?? 'Sync failed',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      if (syncViewModel.canRetry)
                        TextButton(
                          onPressed: () => syncViewModel.syncRecentData(days: 7),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        )
                      else
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.white60,
                          ),
                          onPressed: syncViewModel.clearError,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
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
              color: Colors.white60,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build placeholder card for future providers
  Widget _buildPlaceholderCard(String name, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Colors.white38,
                size: 28,
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
                      color: Colors.white38,
                    ),
                  ),
                  const Text(
                    'Coming soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Not Available',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white38,
                ),
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
