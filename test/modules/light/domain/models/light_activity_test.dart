import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/modules/light/domain/models/light_activity.dart';
import 'package:sleepbalance/modules/shared/domain/models/intervention_activity.dart';

void main() {
  group('LightActivity', () {
    final testDate = DateTime(2025, 1, 15);
    final testTimestamp = DateTime(2025, 1, 15, 8, 30);

    group('constructor', () {
      test('creates activity with required light-specific data', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          completedAt: testTimestamp,
          durationMinutes: 30,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
        );

        expect(activity.id, 'test-id');
        expect(activity.userId, 'user-1');
        expect(activity.moduleId, 'light');
        expect(activity.lightType, 'natural_sunlight');
        expect(activity.wasCompleted, true);
        expect(activity.durationMinutes, 30);
      });

      test('stores light-specific data in moduleSpecificData', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'light_box',
          location: 'living room',
          weather: 'sunny',
          deviceUsed: 'Philips Wake-Up Light',
        );

        final data = activity.moduleSpecificData!;
        expect(data['light_type'], 'light_box');
        expect(data['location'], 'living room');
        expect(data['weather'], 'sunny');
        expect(data['device_used'], 'Philips Wake-Up Light');
      });

      test('excludes null optional fields from moduleSpecificData', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'blue_light',
        );

        final data = activity.moduleSpecificData!;
        expect(data.containsKey('light_type'), true);
        expect(data.containsKey('location'), false);
        expect(data.containsKey('weather'), false);
        expect(data.containsKey('device_used'), false);
      });
    });

    group('fromInterventionActivity', () {
      test('converts base InterventionActivity to LightActivity', () {
        final baseActivity = InterventionActivity(
          id: 'test-id',
          userId: 'user-1',
          moduleId: 'light',
          activityDate: testDate,
          wasCompleted: true,
          completedAt: testTimestamp,
          durationMinutes: 30,
          createdAt: testTimestamp,
          moduleSpecificData: {
            'light_type': 'light_box',
            'location': 'bedroom',
          },
        );

        final lightActivity = LightActivity.fromInterventionActivity(baseActivity);

        expect(lightActivity.id, 'test-id');
        expect(lightActivity.userId, 'user-1');
        expect(lightActivity.lightType, 'light_box');
        expect(lightActivity.location, 'bedroom');
        expect(lightActivity.durationMinutes, 30);
      });

      test('throws error for non-light intervention', () {
        final sportActivity = InterventionActivity(
          id: 'test-id',
          userId: 'user-1',
          moduleId: 'sport',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
        );

        expect(
          () => LightActivity.fromInterventionActivity(sportActivity),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('defaults to natural_sunlight when light_type missing', () {
        final baseActivity = InterventionActivity(
          id: 'test-id',
          userId: 'user-1',
          moduleId: 'light',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          moduleSpecificData: {},
        );

        final lightActivity = LightActivity.fromInterventionActivity(baseActivity);

        expect(lightActivity.lightType, 'natural_sunlight');
      });

      test('handles null moduleSpecificData', () {
        final baseActivity = InterventionActivity(
          id: 'test-id',
          userId: 'user-1',
          moduleId: 'light',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
        );

        final lightActivity = LightActivity.fromInterventionActivity(baseActivity);

        expect(lightActivity.lightType, 'natural_sunlight');
        expect(lightActivity.location, null);
        expect(lightActivity.weather, null);
        expect(lightActivity.deviceUsed, null);
      });
    });

    group('fromDatabase', () {
      test('creates LightActivity from database map', () {
        final dbMap = {
          'id': 'test-id',
          'user_id': 'user-1',
          'module_id': 'light',
          'activity_date': '2025-01-15',
          'was_completed': 1,
          'completed_at': '2025-01-15T08:30:00.000Z',
          'duration_minutes': 30,
          'time_of_day': 'morning',
          'intensity': 'medium',
          'notes': 'Felt energized',
          'module_specific_data': '{"light_type":"light_box","location":"office"}',
          'created_at': '2025-01-15T08:00:00.000Z',
          'updated_at': '2025-01-15T08:30:00.000Z',
        };

        final activity = LightActivity.fromDatabase(dbMap);

        expect(activity.id, 'test-id');
        expect(activity.userId, 'user-1');
        expect(activity.moduleId, 'light');
        expect(activity.lightType, 'light_box');
        expect(activity.location, 'office');
        expect(activity.durationMinutes, 30);
        expect(activity.timeOfDay, 'morning');
        expect(activity.notes, 'Felt energized');
      });
    });

    group('fromJson', () {
      test('creates LightActivity from JSON', () {
        final json = {
          'id': 'test-id',
          'userId': 'user-1',
          'moduleId': 'light',
          'activityDate': '2025-01-15T00:00:00.000Z',
          'wasCompleted': true,
          'completedAt': '2025-01-15T08:30:00.000Z',
          'durationMinutes': 30,
          'createdAt': '2025-01-15T08:00:00.000Z',
          'moduleSpecificData': {
            'light_type': 'red_light',
            'device_used': 'Red Light Panel',
          },
        };

        final activity = LightActivity.fromJson(json);

        expect(activity.id, 'test-id');
        expect(activity.lightType, 'red_light');
        expect(activity.deviceUsed, 'Red Light Panel');
      });
    });

    group('toDatabase', () {
      test('converts to database map with JSON moduleSpecificData', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          completedAt: testTimestamp,
          durationMinutes: 30,
          createdAt: testTimestamp,
          lightType: 'blue_light',
          location: 'bedroom',
          weather: 'cloudy',
        );

        final dbMap = activity.toDatabase();

        expect(dbMap['id'], 'test-id');
        expect(dbMap['module_id'], 'light');
        expect(dbMap['was_completed'], 1);
        expect(dbMap['duration_minutes'], 30);

        // moduleSpecificData should be JSON string
        expect(dbMap['module_specific_data'], isA<String>());
        expect(dbMap['module_specific_data'], contains('blue_light'));
        expect(dbMap['module_specific_data'], contains('bedroom'));
      });
    });

    group('toJson', () {
      test('converts to JSON with moduleSpecificData map', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
          location: 'outdoor',
          weather: 'sunny',
        );

        final json = activity.toJson();

        expect(json['id'], 'test-id');
        expect(json['moduleId'], 'light');
        expect(json['moduleSpecificData'], isA<Map>());
        expect(json['moduleSpecificData']['light_type'], 'natural_sunlight');
        expect(json['moduleSpecificData']['location'], 'outdoor');
        expect(json['moduleSpecificData']['weather'], 'sunny');
      });
    });

    group('typed getters', () {
      test('lightType getter returns correct value', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'light_box',
        );

        expect(activity.lightType, 'light_box');
      });

      test('location getter returns correct value', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
          location: 'park',
        );

        expect(activity.location, 'park');
      });

      test('weather getter returns correct value', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
          weather: 'partly cloudy',
        );

        expect(activity.weather, 'partly cloudy');
      });

      test('deviceUsed getter returns correct value', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'light_box',
          deviceUsed: 'Verilux HappyLight',
        );

        expect(activity.deviceUsed, 'Verilux HappyLight');
      });

      test('getters return null for missing optional fields', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'blue_light',
        );

        expect(activity.location, null);
        expect(activity.weather, null);
        expect(activity.deviceUsed, null);
      });
    });

    group('copyWithLight', () {
      test('creates copy with updated light-specific fields', () {
        final original = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
          location: 'outdoor',
        );

        final updated = original.copyWithLight(
          lightType: 'light_box',
          location: 'office',
          deviceUsed: 'HappyLight',
        );

        expect(updated.lightType, 'light_box');
        expect(updated.location, 'office');
        expect(updated.deviceUsed, 'HappyLight');
        expect(updated.id, original.id);
        expect(updated.userId, original.userId);
      });

      test('preserves original when no fields specified', () {
        final original = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'blue_light',
          location: 'bedroom',
        );

        final copy = original.copyWithLight();

        expect(copy.lightType, original.lightType);
        expect(copy.location, original.location);
        expect(copy.id, original.id);
      });
    });

    group('getDescription', () {
      test('includes light type and duration', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
          durationMinutes: 30,
        );

        final description = activity.getDescription();

        expect(description, contains('Natural Sunlight'));
        expect(description, contains('30 minutes'));
      });

      test('includes location when provided', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'light_box',
          location: 'office',
          durationMinutes: 20,
        );

        final description = activity.getDescription();

        expect(description, contains('Light Box'));
        expect(description, contains('office'));
      });

      test('includes weather when provided', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
          weather: 'sunny',
        );

        final description = activity.getDescription();

        expect(description, contains('sunny'));
      });

      test('handles all light type labels correctly', () {
        final types = {
          'natural_sunlight': 'Natural Sunlight',
          'light_box': 'Light Box',
          'blue_light': 'Blue Light Therapy',
          'red_light': 'Red Light Therapy',
        };

        types.forEach((type, expectedLabel) {
          final activity = LightActivity(
            id: 'test-id',
            userId: 'user-1',
            activityDate: testDate,
            wasCompleted: true,
            createdAt: testTimestamp,
            lightType: type,
          );

          expect(activity.getDescription(), contains(expectedLabel));
        });
      });

      test('uses raw light type for unknown types', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'custom_light',
        );

        final description = activity.getDescription();

        expect(description, contains('custom_light'));
      });
    });

    group('isOutdoorSession', () {
      test('returns true for natural_sunlight', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
        );

        expect(activity.isOutdoorSession, true);
      });

      test('returns true for location containing outdoor', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'light_box',
          location: 'outdoor patio',
        );

        expect(activity.isOutdoorSession, true);
      });

      test('returns false for indoor light box without outdoor location', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'light_box',
          location: 'office',
        );

        expect(activity.isOutdoorSession, false);
      });
    });

    group('usedTherapeuticDevice', () {
      test('returns true for light_box', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'light_box',
        );

        expect(activity.usedTherapeuticDevice, true);
      });

      test('returns true for blue_light', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'blue_light',
        );

        expect(activity.usedTherapeuticDevice, true);
      });

      test('returns true for red_light', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'red_light',
        );

        expect(activity.usedTherapeuticDevice, true);
      });

      test('returns false for natural_sunlight', () {
        final activity = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testTimestamp,
          lightType: 'natural_sunlight',
        );

        expect(activity.usedTherapeuticDevice, false);
      });
    });

    group('round-trip database persistence', () {
      test('toDatabase -> fromDatabase preserves all data', () {
        final original = LightActivity(
          id: 'test-id',
          userId: 'user-1',
          activityDate: testDate,
          wasCompleted: true,
          completedAt: testTimestamp,
          durationMinutes: 30,
          timeOfDay: 'morning',
          intensity: 'medium',
          notes: 'Great session',
          createdAt: testTimestamp,
          updatedAt: testTimestamp,
          lightType: 'light_box',
          location: 'bedroom',
          weather: 'overcast',
          deviceUsed: 'Philips Wake-Up Light',
        );

        final dbMap = original.toDatabase();
        final restored = LightActivity.fromDatabase(dbMap);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.lightType, original.lightType);
        expect(restored.location, original.location);
        expect(restored.weather, original.weather);
        expect(restored.deviceUsed, original.deviceUsed);
        expect(restored.durationMinutes, original.durationMinutes);
        expect(restored.timeOfDay, original.timeOfDay);
        expect(restored.intensity, original.intensity);
        expect(restored.notes, original.notes);
      });
    });
  });
}
