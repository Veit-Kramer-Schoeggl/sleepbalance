import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/modules/shared/domain/models/intervention_activity.dart';
import 'package:sleepbalance/modules/shared/domain/models/module.dart';
import 'package:sleepbalance/modules/shared/domain/models/user_module_config.dart';

void main() {
  group('Models Database Integration Tests', () {
    group('InterventionActivity Database Round-Trip', () {
      test('complete activity with all fields survives database round-trip', () {
        // Create a complete intervention activity
        final original = InterventionActivity(
          id: 'test-activity-123',
          userId: 'user-456',
          moduleId: 'light',
          activityDate: DateTime(2025, 1, 15, 7, 30),
          wasCompleted: true,
          completedAt: DateTime(2025, 1, 15, 7, 45),
          durationMinutes: 30,
          timeOfDay: 'morning',
          intensity: 'medium',
          moduleSpecificData: {
            'light_type': 'natural_sunlight',
            'location': 'outdoor',
            'weather': 'sunny',
            'temperature': 18.5,
          },
          notes: 'Great morning session!',
          createdAt: DateTime(2025, 1, 15, 6, 0),
          updatedAt: DateTime(2025, 1, 15, 7, 50),
        );

        // Convert to database format (simulates INSERT)
        final dbMap = original.toDatabase();

        // Verify database format
        expect(dbMap['id'], 'test-activity-123');
        expect(dbMap['was_completed'], 1); // Boolean as int
        expect(dbMap['activity_date'], '2025-01-15'); // Date only
        expect(dbMap['module_specific_data'], isA<String>()); // JSON string

        // Convert back from database format (simulates SELECT)
        final restored = InterventionActivity.fromDatabase(dbMap);

        // Verify all fields match
        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.moduleId, original.moduleId);
        expect(restored.activityDate.year, original.activityDate.year);
        expect(restored.activityDate.month, original.activityDate.month);
        expect(restored.activityDate.day, original.activityDate.day);
        expect(restored.wasCompleted, original.wasCompleted);
        expect(restored.completedAt?.year, original.completedAt?.year);
        expect(restored.durationMinutes, original.durationMinutes);
        expect(restored.timeOfDay, original.timeOfDay);
        expect(restored.intensity, original.intensity);
        expect(restored.notes, original.notes);

        // Verify moduleSpecificData preserved correctly
        expect(restored.moduleSpecificData, isNotNull);
        expect(restored.moduleSpecificData!['light_type'], 'natural_sunlight');
        expect(restored.moduleSpecificData!['location'], 'outdoor');
        expect(restored.moduleSpecificData!['weather'], 'sunny');
        expect(restored.moduleSpecificData!['temperature'], 18.5);
      });

      test('minimal activity with required fields only survives round-trip', () {
        final original = InterventionActivity(
          id: 'minimal-id',
          userId: 'user-id',
          moduleId: 'meditation',
          activityDate: DateTime(2025, 1, 15),
          wasCompleted: false, // Not completed
          createdAt: DateTime(2025, 1, 15, 20, 0),
          // All optional fields null
        );

        final dbMap = original.toDatabase();
        final restored = InterventionActivity.fromDatabase(dbMap);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.moduleId, original.moduleId);
        expect(restored.wasCompleted, false);
        expect(restored.completedAt, isNull);
        expect(restored.durationMinutes, isNull);
        expect(restored.timeOfDay, isNull);
        expect(restored.intensity, isNull);
        expect(restored.moduleSpecificData, isNull);
        expect(restored.notes, isNull);
      });

      test('complex moduleSpecificData with nested objects survives round-trip',
          () {
        final original = InterventionActivity(
          id: 'complex-id',
          userId: 'user-id',
          moduleId: 'sport',
          activityDate: DateTime(2025, 1, 15),
          wasCompleted: true,
          createdAt: DateTime(2025, 1, 15, 10, 0),
          moduleSpecificData: {
            'activity_type': 'running',
            'distance_km': 5.2,
            'route': {
              'start': 'home',
              'end': 'park',
              'elevation_gain': 120,
            },
            'heart_rate_zones': [120, 145, 165],
            'weather_conditions': {
              'temperature': 15,
              'humidity': 65,
              'wind_speed': 10,
            }
          },
        );

        final dbMap = original.toDatabase();
        final restored = InterventionActivity.fromDatabase(dbMap);

        // Verify complex nested structure
        expect(restored.moduleSpecificData, isNotNull);
        expect(restored.moduleSpecificData!['activity_type'], 'running');
        expect(restored.moduleSpecificData!['distance_km'], 5.2);

        // Nested object
        final route = restored.moduleSpecificData!['route'] as Map;
        expect(route['start'], 'home');
        expect(route['end'], 'park');
        expect(route['elevation_gain'], 120);

        // Array
        final zones = restored.moduleSpecificData!['heart_rate_zones'] as List;
        expect(zones, [120, 145, 165]);

        // Nested weather object
        final weather =
            restored.moduleSpecificData!['weather_conditions'] as Map;
        expect(weather['temperature'], 15);
        expect(weather['humidity'], 65);
        expect(weather['wind_speed'], 10);
      });
    });

    group('Module Database Round-Trip', () {
      test('complete module with all fields survives database round-trip', () {
        final original = Module(
          id: 'light',
          name: 'light_therapy',
          displayName: 'Light Therapy',
          description: 'Optimize circadian rhythm through light exposure',
          icon: 'light_icon.svg',
          isActive: true,
          createdAt: DateTime(2025, 1, 1, 10, 0),
        );

        final dbMap = original.toDatabase();
        final restored = Module.fromDatabase(dbMap);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.displayName, original.displayName);
        expect(restored.description, original.description);
        expect(restored.icon, original.icon);
        expect(restored.isActive, original.isActive);
        expect(restored.createdAt.year, original.createdAt.year);
        expect(restored.createdAt.month, original.createdAt.month);
        expect(restored.createdAt.day, original.createdAt.day);
      });

      test('inactive module survives database round-trip', () {
        final original = Module(
          id: 'deprecated',
          name: 'old_module',
          displayName: 'Deprecated Module',
          isActive: false, // Inactive
          createdAt: DateTime(2024, 6, 15, 12, 0),
        );

        final dbMap = original.toDatabase();

        // Verify database format
        expect(dbMap['is_active'], 0); // Boolean as int

        final restored = Module.fromDatabase(dbMap);

        expect(restored.isActive, false);
        expect(restored.description, isNull);
        expect(restored.icon, isNull);
      });
    });

    group('UserModuleConfig Database Round-Trip', () {
      test('config with complex JSON configuration survives round-trip', () {
        final original = UserModuleConfig(
          id: 'config-123',
          userId: 'user-456',
          moduleId: 'light',
          isEnabled: true,
          configuration: {
            'mode': 'advanced',
            'target_time': '07:30',
            'target_duration_minutes': 30,
            'light_type': 'natural_sunlight',
            'sessions': [
              {
                'id': 'session-1',
                'time': '07:00',
                'duration': 20,
                'type': 'sunlight'
              },
              {
                'id': 'session-2',
                'time': '20:00',
                'duration': 15,
                'type': 'red_light'
              }
            ],
            'notifications': {
              'morning_reminder': {
                'enabled': true,
                'time': '06:45',
              },
              'evening_dim_reminder': {
                'enabled': true,
                'time': '19:30',
              }
            }
          },
          enrolledAt: DateTime(2025, 1, 1, 10, 0),
          updatedAt: DateTime(2025, 1, 15, 8, 30),
        );

        final dbMap = original.toDatabase();

        // Verify database format
        expect(dbMap['is_enabled'], 1); // Boolean as int
        expect(dbMap['configuration'], isA<String>()); // JSON string

        final restored = UserModuleConfig.fromDatabase(dbMap);

        // Verify basic fields
        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.moduleId, original.moduleId);
        expect(restored.isEnabled, original.isEnabled);

        // Verify complex configuration preserved
        expect(restored.configuration['mode'], 'advanced');
        expect(restored.configuration['target_time'], '07:30');
        expect(restored.configuration['target_duration_minutes'], 30);

        // Verify sessions array
        final sessions = restored.configuration['sessions'] as List;
        expect(sessions.length, 2);
        expect(sessions[0]['id'], 'session-1');
        expect(sessions[0]['time'], '07:00');
        expect(sessions[1]['type'], 'red_light');

        // Verify nested notifications
        final notifications = restored.configuration['notifications'] as Map;
        final morningReminder = notifications['morning_reminder'] as Map;
        expect(morningReminder['enabled'], true);
        expect(morningReminder['time'], '06:45');
      });

      test('getConfigValue helper retrieves typed values correctly', () {
        final config = UserModuleConfig(
          id: 'test-id',
          userId: 'user-id',
          moduleId: 'sport',
          isEnabled: true,
          configuration: {
            'mode': 'standard',
            'intensity_level': 'high',
            'duration_minutes': 45,
            'frequency_per_week': 5,
            'prefer_outdoor': true,
          },
          enrolledAt: DateTime(2025, 1, 1),
        );

        final dbMap = config.toDatabase();
        final restored = UserModuleConfig.fromDatabase(dbMap);

        // Test typed value retrieval
        expect(restored.getConfigValue<String>('mode'), 'standard');
        expect(restored.getConfigValue<String>('intensity_level'), 'high');
        expect(restored.getConfigValue<int>('duration_minutes'), 45);
        expect(restored.getConfigValue<int>('frequency_per_week'), 5);
        expect(restored.getConfigValue<bool>('prefer_outdoor'), true);
        expect(restored.getConfigValue<String>('non_existent_key'), isNull);
      });

      test('updateConfigValue creates new instance with updated value', () {
        final original = UserModuleConfig(
          id: 'test-id',
          userId: 'user-id',
          moduleId: 'meditation',
          isEnabled: true,
          configuration: {
            'duration': 10,
            'technique': 'breathing',
          },
          enrolledAt: DateTime(2025, 1, 1),
        );

        // Convert to database and back
        final dbMap = original.toDatabase();
        final restored = UserModuleConfig.fromDatabase(dbMap);

        // Update a value using helper
        final updated = restored.updateConfigValue('duration', 15);

        // Verify original unchanged
        expect(restored.configuration['duration'], 10);

        // Verify new instance has updated value
        expect(updated.configuration['duration'], 15);
        expect(updated.configuration['technique'], 'breathing');

        // Verify updated timestamp changed
        expect(
            updated.updatedAt.isAfter(restored.updatedAt) ||
                updated.updatedAt.isAtSameMomentAs(restored.updatedAt),
            true);
      });
    });

    group('JSON Serialization Round-Trip', () {
      test('InterventionActivity JSON round-trip preserves all data', () {
        final original = InterventionActivity(
          id: 'json-test-id',
          userId: 'user-json',
          moduleId: 'temperature',
          activityDate: DateTime(2025, 1, 15),
          wasCompleted: true,
          completedAt: DateTime(2025, 1, 15, 8, 0),
          durationMinutes: 20,
          timeOfDay: 'morning',
          intensity: 'high',
          moduleSpecificData: {
            'type': 'cold_shower',
            'temperature_celsius': 15,
          },
          notes: 'Invigorating!',
          createdAt: DateTime(2025, 1, 15, 7, 0),
          updatedAt: DateTime(2025, 1, 15, 8, 5),
        );

        // JSON round-trip
        final json = original.toJson();
        final restored = InterventionActivity.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.moduleId, original.moduleId);
        expect(restored.wasCompleted, original.wasCompleted);
        expect(restored.durationMinutes, original.durationMinutes);
        expect(restored.timeOfDay, original.timeOfDay);
        expect(restored.intensity, original.intensity);
        expect(restored.notes, original.notes);
        expect(
            restored.moduleSpecificData!['type'], 'cold_shower');
        expect(restored.moduleSpecificData!['temperature_celsius'], 15);
      });

      test('Module JSON round-trip preserves all data', () {
        final original = Module(
          id: 'sport',
          name: 'sport_module',
          displayName: 'Sport & Exercise',
          description: 'Optimize exercise timing for better sleep',
          icon: 'sport_icon.svg',
          isActive: true,
          createdAt: DateTime(2025, 1, 1, 10, 0),
        );

        final json = original.toJson();
        final restored = Module.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.name, original.name);
        expect(restored.displayName, original.displayName);
        expect(restored.description, original.description);
        expect(restored.icon, original.icon);
        expect(restored.isActive, original.isActive);
      });

      test('UserModuleConfig JSON round-trip preserves complex configuration',
          () {
        final original = UserModuleConfig(
          id: 'config-json',
          userId: 'user-json',
          moduleId: 'journaling',
          isEnabled: true,
          configuration: {
            'prompts_enabled': true,
            'default_prompt': 'How did you sleep?',
            'custom_prompts': ['What helped?', 'What hindered?'],
            'reminder_time': '21:00',
          },
          enrolledAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 15),
        );

        final json = original.toJson();
        final restored = UserModuleConfig.fromJson(json);

        expect(restored.id, original.id);
        expect(restored.userId, original.userId);
        expect(restored.moduleId, original.moduleId);
        expect(restored.isEnabled, original.isEnabled);
        expect(restored.configuration['prompts_enabled'], true);
        expect(restored.configuration['default_prompt'], 'How did you sleep?');

        final customPrompts = restored.configuration['custom_prompts'] as List;
        expect(customPrompts, ['What helped?', 'What hindered?']);
      });
    });
  });
}
