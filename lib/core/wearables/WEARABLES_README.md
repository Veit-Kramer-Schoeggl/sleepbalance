# Wearables Integration

## Overview

The wearables integration system provides OAuth-based authentication and data synchronization with external sleep tracking devices. The architecture follows a clean, layered approach that separates authentication, data storage, and presentation concerns.

## How It Works

### Authentication Flow

Users authenticate with wearable providers through industry-standard OAuth 2.0 protocols. The system stores access tokens, refresh tokens, and token expiration timestamps locally in SQLite. When tokens expire, the system automatically refreshes them using stored refresh tokens to maintain continuous access to wearable data.

Each connection is tied to a specific user and provider combination. Users can have multiple active connections simultaneously, though typically only one provider is used at a time. Connection status, last sync timestamps, and granted permissions are tracked for each provider.

### Supported Providers

**Currently Implemented:**
- **Fitbit**: Full OAuth integration with access to sleep, activity, heart rate, and profile data

**Planned:**
- **Apple Health**: iOS native HealthKit integration
- **Google Fit**: Android native fitness data access
- **Garmin**: OAuth-based connection for Garmin devices

### Data Synchronization

The sync system operates on a scheduled basis, fetching sleep data from connected wearables and transforming it into the app's unified sleep record format. Each sync attempt is logged with detailed metadata including success/failure status, number of records fetched, and any errors encountered.

Sync operations are idempotent—running multiple syncs for the same date range will not create duplicate records. The system tracks the last successful sync timestamp for each provider and typically fetches only new data since that point.

### Token Management

Access tokens have limited lifespans (typically 8 hours for Fitbit). The system monitors token expiration and proactively refreshes tokens before they expire. If a refresh fails, the user is prompted to re-authenticate through the OAuth flow.

Refresh tokens are stored securely and used only for obtaining new access tokens. The system never stores user passwords or other sensitive authentication credentials.

### Error Handling

Connection failures, API rate limits, and network errors are gracefully handled. Each sync attempt records detailed error information to help diagnose issues. Users see friendly error messages in the UI while detailed technical information is logged for debugging.

If a provider's API is unavailable, the system retries with exponential backoff. Permanent failures (like revoked access) prompt the user to reconnect their device.

## Architecture

### Layered Design

The wearables system follows clean architecture with three distinct layers:

**Domain Layer** (`domain/`): Contains business logic, data models, and repository interfaces. This layer defines what the system does without specifying how. Models like `WearableCredentials` and `WearableSyncRecord` represent core business concepts. Repository interfaces define contracts for data access without implementation details.

**Data Layer** (`data/`): Implements data access through datasources and repository implementations. Local datasources handle SQLite operations while API datasources communicate with external provider APIs. Repository implementations orchestrate these datasources and add business logic like token validation and conflict resolution.

**Presentation Layer** (`presentation/`): Manages UI state and user interactions through ViewModels and screens. ViewModels react to user actions, coordinate with repositories, and expose UI state through ChangeNotifier. Screens consume ViewModels via Provider for reactive updates.

### Provider Pattern

The system uses Flutter's Provider package for dependency injection and state management. Datasources, repositories, and ViewModels are registered in the app's provider tree, allowing clean dependency flow from data layer to presentation layer.

ViewModels extend ChangeNotifier to provide reactive UI updates. When data changes (like completing OAuth or syncing sleep data), ViewModels notify listeners and the UI rebuilds automatically.

## File Structure

```
lib/core/wearables/
├── domain/              # Business logic & models (what)
│   ├── enums/          # Type-safe provider and status definitions
│   ├── models/         # Data structures for credentials, sync records, sleep data
│   └── repositories/   # Repository interfaces (contracts)
│
├── data/               # Data access implementation (how)
│   ├── datasources/    # Direct database and API access
│   └── repositories/   # Repository implementations with business logic
│
├── presentation/       # UI layer (user interaction)
│   ├── viewmodels/     # State management and business logic coordination
│   ├── screens/        # Full-page UI components
│   └── widgets/        # Reusable UI components (future)
│
└── utils/             # Shared utilities and configuration
```

### Key Files

**Configuration**:
- `utils/fitbit_secrets.dart` - OAuth client credentials and redirect URIs

**Domain Models**:
- `domain/models/wearable_credentials.dart` - OAuth token storage model
- `domain/models/wearable_sync_record.dart` - Sync attempt tracking model
- `domain/models/sleep_data.dart` - Unified sleep data representation

**Repository Interface**:
- `domain/repositories/wearable_auth_repository.dart` - Authentication contract

**Data Access**:
- `data/datasources/wearable_credentials_local_datasource.dart` - SQLite operations
- `data/repositories/wearable_auth_repository_impl.dart` - Repository implementation

**Presentation**:
- `presentation/viewmodels/wearable_connection_viewmodel.dart` - Connection state management
- `presentation/screens/wearable_connection_test_screen.dart` - Test UI for OAuth flow

## Database Schema

The system uses two SQLite tables for persistent storage:

**wearable_connections**: Stores OAuth credentials, token expiration, and connection metadata. Each row represents one user-provider connection with fields for access tokens, refresh tokens, granted scopes, and sync timestamps.

**wearable_sync_history**: Logs every sync attempt with start/end times, success/failure status, record counts, and error messages. This enables troubleshooting and provides sync analytics.

See `core/database/migrations/migration_v7.dart` for complete schema definitions and constraints.

## Development Status

**Phase 1 - COMPLETE**:
- OAuth authentication flow (Fitbit)
- Credential storage and token management
- Connection UI with status display
- Database schema and migrations

**Phase 2 - PLANNED**:
- Sleep data fetching from Fitbit API
- Data transformation to unified sleep record format
- Background sync scheduler
- Conflict resolution between manual and wearable data
- Sync status UI with progress indicators

**Future Phases**:
- Apple Health integration (iOS)
- Google Fit integration (Android)
- Garmin connectivity
- Advanced sync configuration (frequency, date ranges)
- Multi-device aggregation

## Testing

The OAuth flow can be tested through the temporary test screen accessible from Habits Lab. Tap "Fitbit verbinden" to initiate authentication. After granting permissions in the browser, the connection status updates to show connected state, last sync time, and token expiration.

For end-to-end testing:
1. Connect a Fitbit account through OAuth
2. Verify credentials are saved in database
3. Restart app and confirm connection persists
4. Disconnect and verify credentials are removed

See `PHASE_1_PROGRESS_REPORT.md` for detailed implementation notes and test scenarios.

## Security Considerations

OAuth client secrets are stored in source code for development convenience but should be moved to environment variables or secure configuration management for production deployment. The app uses the authorization code flow (not implicit flow) for better security.

Refresh tokens are stored in local SQLite without additional encryption. For production, consider encrypting sensitive database columns using flutter_secure_storage or similar packages.

The system never stores user passwords. All authentication happens through OAuth redirect flows where the user enters credentials directly on the provider's website, not in the app.
