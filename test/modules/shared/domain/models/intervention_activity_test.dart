import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/modules/shared/domain/models/intervention_activity.dart';

void main() {
  group('InterventionActivity', () {
    final testDate = DateTime(2025, 1, 15, 7, 30);
    final testCreated = DateTime(2025, 1, 15, 6, 0);
    final testUpdated = DateTime(2025, 1, 15, 7, 45);

    final sampleActivity = InterventionActivity(
      id: 'test-id-123',
      userId: 'user-456',
      moduleId: 'light',
      activityDate: testDate,
      wasCompleted: true,
      completedAt: testDate,
      durationMinutes: 30,
      timeOfDay: 'morning',
      intensity: 'medium',
      moduleSpecificData: {
        'light_type': 'natural_sunlight',
        'location': 'outdoor',
        'weather': 'sunny',
      },
      notes: 'Great session today!',
      createdAt: testCreated,
      updatedAt: testUpdated,
    );

    group('fromDatabase', () {
      test('parses all fields correctly', () {
        final dbMap = {
          'id': 'test-id-123',
          'user_id': 'user-456',
          'module_id': 'light',
          'activity_date': '2025-01-15',
          'was_completed': 1,
          'completed_at': '2025-01-15T07:30:00.000',
          'duration_minutes': 30,
          'time_of_day': 'morning',
          'intensity': 'medium',
          'module_specific_data':
              '{"light_type":"natural_sunlight","location":"outdoor","weather":"sunny"}',
          'notes': 'Great session today!',
          'created_at': '2025-01-15T06:00:00.000',
          'updated_at': '2025-01-15T07:45:00.000',
        };

        final activity = InterventionActivity.fromDatabase(dbMap);

        expect(activity.id, 'test-id-123');
        expect(activity.userId, 'user-456');
        expect(activity.moduleId, 'light');
        expect(activity.activityDate.year, 2025);
        expect(activity.activityDate.month, 1);
        expect(activity.activityDate.day, 15);
        expect(activity.wasCompleted, true);
        expect(activity.completedAt, isNotNull);
        expect(activity.durationMinutes, 30);
        expect(activity.timeOfDay, 'morning');
        expect(activity.intensity, 'medium');
        expect(activity.moduleSpecificData, isNotNull);
        expect(activity.moduleSpecificData!['light_type'], 'natural_sunlight');
        expect(activity.moduleSpecificData!['location'], 'outdoor');
        expect(activity.moduleSpecificData!['weather'], 'sunny');
        expect(activity.notes, 'Great session today!');
      });

      test('handles wasCompleted false correctly', () {
        final dbMap = {
          'id': 'test-id',
          'user_id': 'user-id',
          'module_id': 'sport',
          'activity_date': '2025-01-15',
          'was_completed': 0, // FALSE
          'completed_at': null,
          'duration_minutes': null,
          'time_of_day': null,
          'intensity': null,
          'module_specific_data': null,
          'notes': null,
          'created_at': '2025-01-15T06:00:00.000',
          'updated_at': '2025-01-15T06:00:00.000',
        };

        final activity = InterventionActivity.fromDatabase(dbMap);

        expect(activity.wasCompleted, false);
      });

      test('handles null optional fields correctly', () {
        final dbMap = {
          'id': 'test-id',
          'user_id': 'user-id',
          'module_id': 'meditation',
          'activity_date': '2025-01-15',
          'was_completed': 1,
          'completed_at': null,
          'duration_minutes': null,
          'time_of_day': null,
          'intensity': null,
          'module_specific_data': null,
          'notes': null,
          'created_at': '2025-01-15T06:00:00.000',
          'updated_at': '2025-01-15T06:00:00.000',
        };

        final activity = InterventionActivity.fromDatabase(dbMap);

        expect(activity.wasCompleted, true);
        expect(activity.completedAt, isNull);
        expect(activity.durationMinutes, isNull);
        expect(activity.timeOfDay, isNull);
        expect(activity.intensity, isNull);
        expect(activity.moduleSpecificData, isNull);
        expect(activity.notes, isNull);
      });

      test('parses moduleSpecificData JSON correctly', () {
        final dbMap = {
          'id': 'test-id',
          'user_id': 'user-id',
          'module_id': 'sport',
          'activity_date': '2025-01-15',
          'was_completed': 1,
          'completed_at': null,
          'duration_minutes': null,
          'time_of_day': null,
          'intensity': 'high',
          'module_specific_data': '{"activity_type":"running","distance_km":5.2}',
          'notes': null,
          'created_at': '2025-01-15T06:00:00.000',
          'updated_at': '2025-01-15T06:00:00.000',
        };

        final activity = InterventionActivity.fromDatabase(dbMap);

        expect(activity.moduleSpecificData, isNotNull);
        expect(activity.moduleSpecificData!['activity_type'], 'running');
        expect(activity.moduleSpecificData!['distance_km'], 5.2);
      });
    });

    group('toDatabase', () {
      test('converts all fields correctly', () {
        final dbMap = sampleActivity.toDatabase();

        expect(dbMap['id'], 'test-id-123');
        expect(dbMap['user_id'], 'user-456');
        expect(dbMap['module_id'], 'light');
        expect(dbMap['activity_date'], '2025-01-15');
        expect(dbMap['was_completed'], 1); // Boolean -> int
        expect(dbMap['completed_at'], '2025-01-15T07:30:00.000');
        expect(dbMap['duration_minutes'], 30);
        expect(dbMap['time_of_day'], 'morning');
        expect(dbMap['intensity'], 'medium');
        expect(dbMap['notes'], 'Great session today!');

        // Verify JSON encoding
        final jsonData = json.decode(dbMap['module_specific_data']);
        expect(jsonData['light_type'], 'natural_sunlight');
        expect(jsonData['location'], 'outdoor');
        expect(jsonData['weather'], 'sunny');
      });

      test('converts wasCompleted false to 0', () {
        final activity = InterventionActivity(
          id: 'test-id',
          userId: 'user-id',
          moduleId: 'sport',
          activityDate: testDate,
          wasCompleted: false, // FALSE
          createdAt: testCreated,
        );

        final dbMap = activity.toDatabase();

        expect(dbMap['was_completed'], 0);
      });

      test('handles null optional fields correctly', () {
        final activity = InterventionActivity(
          id: 'test-id',
          userId: 'user-id',
          moduleId: 'meditation',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testCreated,
          // All optional fields null
        );

        final dbMap = activity.toDatabase();

        expect(dbMap['completed_at'], isNull);
        expect(dbMap['duration_minutes'], isNull);
        expect(dbMap['time_of_day'], isNull);
        expect(dbMap['intensity'], isNull);
        expect(dbMap['module_specific_data'], isNull);
        expect(dbMap['notes'], isNull);
      });

      test('encodes moduleSpecificData as JSON string', () {
        final activity = InterventionActivity(
          id: 'test-id',
          userId: 'user-id',
          moduleId: 'sport',
          activityDate: testDate,
          wasCompleted: true,
          createdAt: testCreated,
          moduleSpecificData: {
            'activity_type': 'swimming',
            'laps': 20,
            'pool_type': 'olympic',
          },
        );

        final dbMap = activity.toDatabase();

        expect(dbMap['module_specific_data'], isA<String>());

        final jsonData = json.decode(dbMap['module_specific_data']);
        expect(jsonData['activity_type'], 'swimming');
        expect(jsonData['laps'], 20);
        expect(jsonData['pool_type'], 'olympic');
      });
    });

    group('copyWith', () {
      test('creates new instance with updated fields', () {
        final updated = sampleActivity.copyWith(
          durationMinutes: 45,
          notes: 'Updated notes',
        );

        expect(updated.id, sampleActivity.id); // Unchanged
        expect(updated.userId, sampleActivity.userId); // Unchanged
        expect(updated.moduleId, sampleActivity.moduleId); // Unchanged
        expect(updated.durationMinutes, 45); // Updated
        expect(updated.notes, 'Updated notes'); // Updated
      });

      test('does not modify original instance', () {
        final original = sampleActivity;
        final updated = original.copyWith(wasCompleted: false);

        expect(original.wasCompleted, true); // Original unchanged
        expect(updated.wasCompleted, false); // Copy changed
      });

      test('returns identical copy when no parameters provided', () {
        final copy = sampleActivity.copyWith();

        expect(copy.id, sampleActivity.id);
        expect(copy.userId, sampleActivity.userId);
        expect(copy.moduleId, sampleActivity.moduleId);
        expect(copy.wasCompleted, sampleActivity.wasCompleted);
        expect(copy.durationMinutes, sampleActivity.durationMinutes);
      });
    });

    group('JSON serialization', () {
      test('toJson and fromJson round-trip', () {
        final json = sampleActivity.toJson();
        final restored = InterventionActivity.fromJson(json);

        expect(restored.id, sampleActivity.id);
        expect(restored.userId, sampleActivity.userId);
        expect(restored.moduleId, sampleActivity.moduleId);
        expect(restored.wasCompleted, sampleActivity.wasCompleted);
        expect(restored.durationMinutes, sampleActivity.durationMinutes);
        expect(restored.timeOfDay, sampleActivity.timeOfDay);
        expect(restored.intensity, sampleActivity.intensity);
        expect(restored.notes, sampleActivity.notes);
      });

      test('handles moduleSpecificData in JSON', () {
        final json = sampleActivity.toJson();

        expect(json['moduleSpecificData'], isNotNull);
        expect(json['moduleSpecificData']['light_type'], 'natural_sunlight');

        final restored = InterventionActivity.fromJson(json);
        expect(restored.moduleSpecificData!['light_type'], 'natural_sunlight');
      });
    });
  });
}
