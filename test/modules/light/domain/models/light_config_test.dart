import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/modules/light/domain/models/light_config.dart';

void main() {
  group('LightConfig', () {
    group('standardDefault', () {
      test('creates valid standard mode configuration', () {
        final config = LightConfig.standardDefault();

        expect(config.mode, 'standard');
        expect(config.targetTime, '07:30');
        expect(config.targetDurationMinutes, 30);
        expect(config.lightType, 'natural_sunlight');
        expect(config.morningReminderEnabled, true);
        expect(config.morningReminderTime, '07:30');
        expect(config.eveningDimReminderEnabled, true);
        expect(config.eveningDimTime, '20:00');
        expect(config.blueBlockerReminderEnabled, true);
        expect(config.blueBlockerTime, '21:00');
        expect(config.sessions, null);
      });

      test('passes validation', () {
        final config = LightConfig.standardDefault();
        expect(config.validate(), null);
      });
    });

    group('advancedDefault', () {
      test('creates valid advanced mode configuration with sessions', () {
        final config = LightConfig.advancedDefault();

        expect(config.mode, 'advanced');
        expect(config.sessions, isNotNull);
        expect(config.sessions!.length, 2);
        expect(config.sessions![0].sessionTime, '07:30');
        expect(config.sessions![0].lightType, 'natural_sunlight');
        expect(config.sessions![1].sessionTime, '20:00');
        expect(config.sessions![1].lightType, 'red_light');
      });

      test('passes validation', () {
        final config = LightConfig.advancedDefault();
        expect(config.validate(), null);
      });
    });

    group('fromJson/toJson', () {
      test('standard mode round-trip preserves all fields', () {
        final original = LightConfig.standardDefault();
        final json = original.toJson();
        final restored = LightConfig.fromJson(json);

        expect(restored.mode, original.mode);
        expect(restored.targetTime, original.targetTime);
        expect(restored.targetDurationMinutes, original.targetDurationMinutes);
        expect(restored.lightType, original.lightType);
        expect(restored.morningReminderEnabled, original.morningReminderEnabled);
        expect(restored.morningReminderTime, original.morningReminderTime);
        expect(restored.eveningDimReminderEnabled, original.eveningDimReminderEnabled);
        expect(restored.eveningDimTime, original.eveningDimTime);
        expect(restored.blueBlockerReminderEnabled, original.blueBlockerReminderEnabled);
        expect(restored.blueBlockerTime, original.blueBlockerTime);
        expect(restored.sessions, original.sessions);
      });

      test('advanced mode round-trip preserves sessions', () {
        final original = LightConfig(
          mode: 'advanced',
          sessions: [
            LightSession(
              id: 'session1',
              sessionTime: '08:00',
              durationMinutes: 25,
              lightType: 'light_box',
              isEnabled: true,
            ),
          ],
        );

        final json = original.toJson();
        final restored = LightConfig.fromJson(json);

        expect(restored.mode, 'advanced');
        expect(restored.sessions, isNotNull);
        expect(restored.sessions!.length, 1);
        expect(restored.sessions![0].id, 'session1');
        expect(restored.sessions![0].sessionTime, '08:00');
        expect(restored.sessions![0].durationMinutes, 25);
        expect(restored.sessions![0].lightType, 'light_box');
      });

      test('handles missing optional fields with defaults', () {
        final json = {'mode': 'standard'};
        final config = LightConfig.fromJson(json);

        expect(config.mode, 'standard');
        expect(config.morningReminderEnabled, true);
        expect(config.morningReminderTime, '07:30');
        expect(config.eveningDimReminderEnabled, true);
        expect(config.eveningDimTime, '20:00');
        expect(config.blueBlockerReminderEnabled, true);
        expect(config.blueBlockerTime, '21:00');
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original = LightConfig.standardDefault();
        final updated = original.copyWith(
          targetTime: '08:00',
          targetDurationMinutes: 45,
          lightType: 'light_box',
        );

        expect(updated.targetTime, '08:00');
        expect(updated.targetDurationMinutes, 45);
        expect(updated.lightType, 'light_box');
        // Original fields preserved
        expect(updated.mode, original.mode);
        expect(updated.morningReminderEnabled, original.morningReminderEnabled);
      });

      test('preserves original when no fields specified', () {
        final original = LightConfig.standardDefault();
        final copy = original.copyWith();

        expect(copy.targetTime, original.targetTime);
        expect(copy.targetDurationMinutes, original.targetDurationMinutes);
        expect(copy.lightType, original.lightType);
      });
    });

    group('validate', () {
      test('rejects invalid mode', () {
        final config = LightConfig(mode: 'invalid');
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('Mode must be'));
      });

      test('standard mode: rejects missing targetTime', () {
        final config = LightConfig(
          mode: 'standard',
          targetDurationMinutes: 30,
          lightType: 'natural_sunlight',
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('requires targetTime'));
      });

      test('standard mode: rejects missing targetDurationMinutes', () {
        final config = LightConfig(
          mode: 'standard',
          targetTime: '07:30',
          lightType: 'natural_sunlight',
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('requires targetDurationMinutes'));
      });

      test('standard mode: rejects duration below 15 minutes', () {
        final config = LightConfig(
          mode: 'standard',
          targetTime: '07:30',
          targetDurationMinutes: 10,
          lightType: 'natural_sunlight',
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('15-60 minutes'));
      });

      test('standard mode: rejects duration above 60 minutes', () {
        final config = LightConfig(
          mode: 'standard',
          targetTime: '07:30',
          targetDurationMinutes: 65,
          lightType: 'natural_sunlight',
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('15-60 minutes'));
      });

      test('standard mode: rejects missing lightType', () {
        final config = LightConfig(
          mode: 'standard',
          targetTime: '07:30',
          targetDurationMinutes: 30,
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('requires lightType'));
      });

      test('standard mode: rejects invalid lightType', () {
        final config = LightConfig(
          mode: 'standard',
          targetTime: '07:30',
          targetDurationMinutes: 30,
          lightType: 'invalid_type',
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('Invalid light type'));
      });

      test('standard mode: rejects invalid time format', () {
        final config = LightConfig(
          mode: 'standard',
          targetTime: '25:00', // Invalid hour
          targetDurationMinutes: 30,
          lightType: 'natural_sunlight',
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('Invalid targetTime format'));
      });

      test('advanced mode: rejects missing sessions', () {
        final config = LightConfig(mode: 'advanced');
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('requires at least one session'));
      });

      test('advanced mode: validates session constraints', () {
        final config = LightConfig(
          mode: 'advanced',
          sessions: [
            LightSession(
              id: 'session1',
              sessionTime: '07:30',
              durationMinutes: 3, // Too short for advanced mode
              lightType: 'natural_sunlight',
            ),
          ],
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('Duration must be 5-120 minutes'));
      });

      test('rejects invalid morningReminderTime', () {
        final config = LightConfig.standardDefault().copyWith(
          morningReminderTime: '99:99',
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('Invalid morningReminderTime'));
      });

      test('rejects invalid eveningDimTime', () {
        final config = LightConfig.standardDefault().copyWith(
          eveningDimTime: 'not-a-time',
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('Invalid eveningDimTime'));
      });

      test('rejects invalid blueBlockerTime', () {
        final config = LightConfig.standardDefault().copyWith(
          blueBlockerTime: '24:00', // Hour 24 is invalid
        );
        final error = config.validate();

        expect(error, isNotNull);
        expect(error, contains('Invalid blueBlockerTime'));
      });

      test('accepts all valid light types', () {
        final validTypes = [
          'natural_sunlight',
          'light_box',
          'blue_light',
          'red_light',
        ];

        for (final type in validTypes) {
          final config = LightConfig(
            mode: 'standard',
            targetTime: '07:30',
            targetDurationMinutes: 30,
            lightType: type,
          );
          expect(config.validate(), null, reason: 'Type $type should be valid');
        }
      });
    });
  });

  group('LightSession', () {
    group('fromJson/toJson', () {
      test('round-trip preserves all fields', () {
        final original = LightSession(
          id: 'test-id',
          sessionTime: '08:00',
          durationMinutes: 30,
          lightType: 'light_box',
          isEnabled: false,
        );

        final json = original.toJson();
        final restored = LightSession.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.sessionTime, original.sessionTime);
        expect(restored.durationMinutes, original.durationMinutes);
        expect(restored.lightType, original.lightType);
        expect(restored.isEnabled, original.isEnabled);
      });

      test('defaults isEnabled to true when missing', () {
        final json = {
          'id': 'test-id',
          'sessionTime': '08:00',
          'durationMinutes': 30,
          'lightType': 'natural_sunlight',
        };
        final session = LightSession.fromJson(json);

        expect(session.isEnabled, true);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final original = LightSession(
          id: 'id1',
          sessionTime: '07:30',
          durationMinutes: 30,
          lightType: 'natural_sunlight',
        );

        final updated = original.copyWith(
          sessionTime: '08:00',
          durationMinutes: 45,
        );

        expect(updated.sessionTime, '08:00');
        expect(updated.durationMinutes, 45);
        expect(updated.id, original.id);
        expect(updated.lightType, original.lightType);
      });
    });

    group('validate', () {
      test('rejects duration below 5 minutes', () {
        final session = LightSession(
          id: 'id1',
          sessionTime: '07:30',
          durationMinutes: 3,
          lightType: 'natural_sunlight',
        );

        expect(session.validate(), contains('Duration must be 5-120 minutes'));
      });

      test('rejects duration above 120 minutes', () {
        final session = LightSession(
          id: 'id1',
          sessionTime: '07:30',
          durationMinutes: 125,
          lightType: 'natural_sunlight',
        );

        expect(session.validate(), contains('Duration must be 5-120 minutes'));
      });

      test('rejects invalid time format', () {
        final session = LightSession(
          id: 'id1',
          sessionTime: 'not-a-time',
          durationMinutes: 30,
          lightType: 'natural_sunlight',
        );

        expect(session.validate(), contains('Invalid time format'));
      });

      test('rejects invalid hour', () {
        final session = LightSession(
          id: 'id1',
          sessionTime: '25:00',
          durationMinutes: 30,
          lightType: 'natural_sunlight',
        );

        expect(session.validate(), contains('Hour must be 0-23'));
      });

      test('rejects invalid minute', () {
        final session = LightSession(
          id: 'id1',
          sessionTime: '08:60',
          durationMinutes: 30,
          lightType: 'natural_sunlight',
        );

        expect(session.validate(), contains('Minute must be 0-59'));
      });

      test('rejects invalid light type', () {
        final session = LightSession(
          id: 'id1',
          sessionTime: '07:30',
          durationMinutes: 30,
          lightType: 'invalid_type',
        );

        expect(session.validate(), contains('Invalid light type'));
      });

      test('accepts valid session', () {
        final session = LightSession(
          id: 'id1',
          sessionTime: '07:30',
          durationMinutes: 30,
          lightType: 'natural_sunlight',
        );

        expect(session.validate(), null);
      });
    });
  });
}
