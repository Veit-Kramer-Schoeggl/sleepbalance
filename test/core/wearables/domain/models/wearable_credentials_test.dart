import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/core/utils/database_date_utils.dart';
import 'package:sleepbalance/core/wearables/domain/enums/wearable_provider.dart';
import 'package:sleepbalance/core/wearables/domain/models/wearable_credentials.dart';
import 'package:sleepbalance/shared/constants/database_constants.dart';

void main() {
  group('WearableCredentials', () {
    late DateTime testConnectedAt;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;
    late DateTime testTokenExpiresAt;
    late DateTime testLastSyncAt;

    setUp(() {
      testConnectedAt = DateTime(2025, 11, 16, 10, 0);
      testCreatedAt = DateTime(2025, 11, 16, 10, 0);
      testUpdatedAt = DateTime(2025, 11, 16, 10, 30);
      testTokenExpiresAt = DateTime(2025, 11, 16, 18, 0);
      testLastSyncAt = DateTime(2025, 11, 16, 12, 0);
    });

    group('Constructor and basic properties', () {
      test('creates with required fields only', () {
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: null,
          tokenExpiresAt: null,
          userExternalId: null,
          grantedScopes: null,
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(credentials.id, equals('test-id'));
        expect(credentials.userId, equals('user-123'));
        expect(credentials.provider, equals(WearableProvider.fitbit));
        expect(credentials.accessToken, equals('access-token-123'));
        expect(credentials.refreshToken, isNull);
        expect(credentials.tokenExpiresAt, isNull);
        expect(credentials.userExternalId, isNull);
        expect(credentials.grantedScopes, isNull);
        expect(credentials.isActive, isTrue);
        expect(credentials.lastSyncAt, isNull);
      });

      test('creates with all fields', () {
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
          tokenExpiresAt: testTokenExpiresAt,
          userExternalId: 'fitbit-user-789',
          grantedScopes: ['sleep', 'activity', 'heartrate'],
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: testLastSyncAt,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(credentials.refreshToken, equals('refresh-token-456'));
        expect(credentials.tokenExpiresAt, equals(testTokenExpiresAt));
        expect(credentials.userExternalId, equals('fitbit-user-789'));
        expect(credentials.grantedScopes, equals(['sleep', 'activity', 'heartrate']));
        expect(credentials.lastSyncAt, equals(testLastSyncAt));
      });
    });

    group('Database serialization', () {
      test('fromDatabase with all fields', () {
        final map = {
          WEARABLE_CONNECTIONS_ID: 'test-id',
          WEARABLE_CONNECTIONS_USER_ID: 'user-123',
          WEARABLE_CONNECTIONS_PROVIDER: 'fitbit',
          WEARABLE_CONNECTIONS_ACCESS_TOKEN: 'access-token-123',
          WEARABLE_CONNECTIONS_REFRESH_TOKEN: 'refresh-token-456',
          WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT: DatabaseDateUtils.toTimestamp(testTokenExpiresAt),
          WEARABLE_CONNECTIONS_USER_EXTERNAL_ID: 'fitbit-user-789',
          WEARABLE_CONNECTIONS_GRANTED_SCOPES: json.encode(['sleep', 'activity']),
          WEARABLE_CONNECTIONS_IS_ACTIVE: 1,
          WEARABLE_CONNECTIONS_CONNECTED_AT: DatabaseDateUtils.toTimestamp(testConnectedAt),
          WEARABLE_CONNECTIONS_LAST_SYNC_AT: DatabaseDateUtils.toTimestamp(testLastSyncAt),
          WEARABLE_CONNECTIONS_CREATED_AT: DatabaseDateUtils.toTimestamp(testCreatedAt),
          WEARABLE_CONNECTIONS_UPDATED_AT: DatabaseDateUtils.toTimestamp(testUpdatedAt),
        };

        final credentials = WearableCredentials.fromDatabase(map);

        expect(credentials.id, equals('test-id'));
        expect(credentials.userId, equals('user-123'));
        expect(credentials.provider, equals(WearableProvider.fitbit));
        expect(credentials.accessToken, equals('access-token-123'));
        expect(credentials.refreshToken, equals('refresh-token-456'));
        expect(credentials.tokenExpiresAt, equals(testTokenExpiresAt));
        expect(credentials.userExternalId, equals('fitbit-user-789'));
        expect(credentials.grantedScopes, equals(['sleep', 'activity']));
        expect(credentials.isActive, isTrue);
        expect(credentials.connectedAt, equals(testConnectedAt));
        expect(credentials.lastSyncAt, equals(testLastSyncAt));
        expect(credentials.createdAt, equals(testCreatedAt));
        expect(credentials.updatedAt, equals(testUpdatedAt));
      });

      test('fromDatabase with nullable fields as null', () {
        final map = {
          WEARABLE_CONNECTIONS_ID: 'test-id',
          WEARABLE_CONNECTIONS_USER_ID: 'user-123',
          WEARABLE_CONNECTIONS_PROVIDER: 'apple_health',
          WEARABLE_CONNECTIONS_ACCESS_TOKEN: 'access-token-123',
          WEARABLE_CONNECTIONS_REFRESH_TOKEN: null,
          WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT: null,
          WEARABLE_CONNECTIONS_USER_EXTERNAL_ID: null,
          WEARABLE_CONNECTIONS_GRANTED_SCOPES: null,
          WEARABLE_CONNECTIONS_IS_ACTIVE: 0,
          WEARABLE_CONNECTIONS_CONNECTED_AT: DatabaseDateUtils.toTimestamp(testConnectedAt),
          WEARABLE_CONNECTIONS_LAST_SYNC_AT: null,
          WEARABLE_CONNECTIONS_CREATED_AT: DatabaseDateUtils.toTimestamp(testCreatedAt),
          WEARABLE_CONNECTIONS_UPDATED_AT: DatabaseDateUtils.toTimestamp(testUpdatedAt),
        };

        final credentials = WearableCredentials.fromDatabase(map);

        expect(credentials.provider, equals(WearableProvider.appleHealth));
        expect(credentials.refreshToken, isNull);
        expect(credentials.tokenExpiresAt, isNull);
        expect(credentials.userExternalId, isNull);
        expect(credentials.grantedScopes, isNull);
        expect(credentials.isActive, isFalse);
        expect(credentials.lastSyncAt, isNull);
      });

      test('toDatabase with all fields', () {
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.garmin,
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
          tokenExpiresAt: testTokenExpiresAt,
          userExternalId: 'garmin-user-789',
          grantedScopes: ['sleep', 'activity', 'heartrate'],
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: testLastSyncAt,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final map = credentials.toDatabase();

        expect(map[WEARABLE_CONNECTIONS_ID], equals('test-id'));
        expect(map[WEARABLE_CONNECTIONS_USER_ID], equals('user-123'));
        expect(map[WEARABLE_CONNECTIONS_PROVIDER], equals('garmin'));
        expect(map[WEARABLE_CONNECTIONS_ACCESS_TOKEN], equals('access-token-123'));
        expect(map[WEARABLE_CONNECTIONS_REFRESH_TOKEN], equals('refresh-token-456'));
        expect(map[WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT], equals(DatabaseDateUtils.toTimestamp(testTokenExpiresAt)));
        expect(map[WEARABLE_CONNECTIONS_USER_EXTERNAL_ID], equals('garmin-user-789'));
        expect(map[WEARABLE_CONNECTIONS_GRANTED_SCOPES], equals(json.encode(['sleep', 'activity', 'heartrate'])));
        expect(map[WEARABLE_CONNECTIONS_IS_ACTIVE], equals(1));
        expect(map[WEARABLE_CONNECTIONS_CONNECTED_AT], equals(DatabaseDateUtils.toTimestamp(testConnectedAt)));
        expect(map[WEARABLE_CONNECTIONS_LAST_SYNC_AT], equals(DatabaseDateUtils.toTimestamp(testLastSyncAt)));
        expect(map[WEARABLE_CONNECTIONS_CREATED_AT], equals(DatabaseDateUtils.toTimestamp(testCreatedAt)));
        expect(map[WEARABLE_CONNECTIONS_UPDATED_AT], equals(DatabaseDateUtils.toTimestamp(testUpdatedAt)));
      });

      test('toDatabase handles nullable fields', () {
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.googleFit,
          accessToken: 'access-token-123',
          refreshToken: null,
          tokenExpiresAt: null,
          userExternalId: null,
          grantedScopes: null,
          isActive: false,
          connectedAt: testConnectedAt,
          lastSyncAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final map = credentials.toDatabase();

        expect(map[WEARABLE_CONNECTIONS_PROVIDER], equals('google_fit'));
        expect(map[WEARABLE_CONNECTIONS_REFRESH_TOKEN], isNull);
        expect(map[WEARABLE_CONNECTIONS_TOKEN_EXPIRES_AT], isNull);
        expect(map[WEARABLE_CONNECTIONS_USER_EXTERNAL_ID], isNull);
        expect(map[WEARABLE_CONNECTIONS_GRANTED_SCOPES], isNull);
        expect(map[WEARABLE_CONNECTIONS_IS_ACTIVE], equals(0));
        expect(map[WEARABLE_CONNECTIONS_LAST_SYNC_AT], isNull);
      });

      test('database round-trip preserves all data', () {
        final original = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
          tokenExpiresAt: testTokenExpiresAt,
          userExternalId: 'fitbit-user-789',
          grantedScopes: ['sleep', 'activity', 'heartrate', 'profile'],
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: testLastSyncAt,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final map = original.toDatabase();
        final restored = WearableCredentials.fromDatabase(map);

        expect(restored.id, equals(original.id));
        expect(restored.userId, equals(original.userId));
        expect(restored.provider, equals(original.provider));
        expect(restored.accessToken, equals(original.accessToken));
        expect(restored.refreshToken, equals(original.refreshToken));
        expect(restored.tokenExpiresAt, equals(original.tokenExpiresAt));
        expect(restored.userExternalId, equals(original.userExternalId));
        expect(restored.grantedScopes, equals(original.grantedScopes));
        expect(restored.isActive, equals(original.isActive));
        expect(restored.connectedAt, equals(original.connectedAt));
        expect(restored.lastSyncAt, equals(original.lastSyncAt));
        expect(restored.createdAt, equals(original.createdAt));
        expect(restored.updatedAt, equals(original.updatedAt));
      });
    });

    group('isTokenExpired method', () {
      test('returns false when tokenExpiresAt is null', () {
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: null,
          tokenExpiresAt: null,
          userExternalId: null,
          grantedScopes: null,
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(credentials.isTokenExpired(), isFalse);
      });

      test('returns false when token not expired', () {
        final futureExpiration = DateTime.now().add(const Duration(hours: 2));
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
          tokenExpiresAt: futureExpiration,
          userExternalId: null,
          grantedScopes: null,
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(credentials.isTokenExpired(), isFalse);
      });

      test('returns true when token expired', () {
        final pastExpiration = DateTime.now().subtract(const Duration(hours: 2));
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
          tokenExpiresAt: pastExpiration,
          userExternalId: null,
          grantedScopes: null,
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(credentials.isTokenExpired(), isTrue);
      });
    });

    group('scopesDisplay getter', () {
      test('returns "None" when grantedScopes is null', () {
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: null,
          tokenExpiresAt: null,
          userExternalId: null,
          grantedScopes: null,
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(credentials.scopesDisplay, equals('None'));
      });

      test('returns "None" when grantedScopes is empty', () {
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: null,
          tokenExpiresAt: null,
          userExternalId: null,
          grantedScopes: [],
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(credentials.scopesDisplay, equals('None'));
      });

      test('returns comma-separated string when scopes exist', () {
        final credentials = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: null,
          tokenExpiresAt: null,
          userExternalId: null,
          grantedScopes: ['sleep', 'activity', 'heartrate'],
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(credentials.scopesDisplay, equals('sleep, activity, heartrate'));
      });
    });

    group('copyWith method', () {
      late WearableCredentials original;

      setUp(() {
        original = WearableCredentials(
          id: 'test-id',
          userId: 'user-123',
          provider: WearableProvider.fitbit,
          accessToken: 'access-token-123',
          refreshToken: 'refresh-token-456',
          tokenExpiresAt: testTokenExpiresAt,
          userExternalId: 'fitbit-user-789',
          grantedScopes: ['sleep', 'activity'],
          isActive: true,
          connectedAt: testConnectedAt,
          lastSyncAt: testLastSyncAt,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );
      });

      test('updates specified fields', () {
        final newExpiration = DateTime.now().add(const Duration(hours: 8));
        final updated = original.copyWith(
          accessToken: 'new-access-token',
          tokenExpiresAt: newExpiration,
          isActive: false,
        );

        expect(updated.accessToken, equals('new-access-token'));
        expect(updated.tokenExpiresAt, equals(newExpiration));
        expect(updated.isActive, isFalse);
        // Unchanged fields
        expect(updated.id, equals('test-id'));
        expect(updated.userId, equals('user-123'));
        expect(updated.refreshToken, equals('refresh-token-456'));
      });

      test('with no parameters returns copy with same values', () {
        final copy = original.copyWith();

        expect(copy.id, equals(original.id));
        expect(copy.userId, equals(original.userId));
        expect(copy.provider, equals(original.provider));
        expect(copy.accessToken, equals(original.accessToken));
        expect(copy.refreshToken, equals(original.refreshToken));
        expect(copy.tokenExpiresAt, equals(original.tokenExpiresAt));
        expect(copy.userExternalId, equals(original.userExternalId));
        expect(copy.grantedScopes, equals(original.grantedScopes));
        expect(copy.isActive, equals(original.isActive));
        expect(copy.connectedAt, equals(original.connectedAt));
        expect(copy.lastSyncAt, equals(original.lastSyncAt));
        expect(copy.createdAt, equals(original.createdAt));
        expect(copy.updatedAt, equals(original.updatedAt));
      });
    });
  });
}
