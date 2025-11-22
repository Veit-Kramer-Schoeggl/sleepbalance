import 'package:flutter_test/flutter_test.dart';
import 'package:sleepbalance/modules/shared/domain/models/module.dart';

void main() {
  group('Module', () {
    final testCreated = DateTime(2025, 1, 1, 10, 0);

    final sampleModule = Module(
      id: 'light',
      name: 'light',
      displayName: 'Light Therapy',
      description: 'Optimize circadian rhythm through light exposure',
      icon: 'light_icon',
      isActive: true,
      createdAt: testCreated,
    );

    group('fromDatabase', () {
      test('parses all fields correctly', () {
        final dbMap = {
          'id': 'light',
          'name': 'light',
          'display_name': 'Light Therapy',
          'description': 'Optimize circadian rhythm through light exposure',
          'icon': 'light_icon',
          'is_active': 1, // Boolean as int
          'created_at': '2025-01-01T10:00:00.000',
        };

        final module = Module.fromDatabase(dbMap);

        expect(module.id, 'light');
        expect(module.name, 'light');
        expect(module.displayName, 'Light Therapy');
        expect(
            module.description, 'Optimize circadian rhythm through light exposure');
        expect(module.icon, 'light_icon');
        expect(module.isActive, true);
        expect(module.createdAt.year, 2025);
        expect(module.createdAt.month, 1);
        expect(module.createdAt.day, 1);
      });

      test('handles isActive false correctly', () {
        final dbMap = {
          'id': 'deprecated_module',
          'name': 'deprecated_module',
          'display_name': 'Deprecated',
          'description': null,
          'icon': null,
          'is_active': 0, // FALSE
          'created_at': '2025-01-01T10:00:00.000',
        };

        final module = Module.fromDatabase(dbMap);

        expect(module.isActive, false);
      });

      test('handles null optional fields correctly', () {
        final dbMap = {
          'id': 'minimal_module',
          'name': 'minimal',
          'display_name': 'Minimal Module',
          'description': null,
          'icon': null,
          'is_active': 1,
          'created_at': '2025-01-01T10:00:00.000',
        };

        final module = Module.fromDatabase(dbMap);

        expect(module.description, isNull);
        expect(module.icon, isNull);
        expect(module.isActive, true);
      });
    });

    group('toDatabase', () {
      test('converts all fields correctly', () {
        final dbMap = sampleModule.toDatabase();

        expect(dbMap['id'], 'light');
        expect(dbMap['name'], 'light');
        expect(dbMap['display_name'], 'Light Therapy');
        expect(
            dbMap['description'], 'Optimize circadian rhythm through light exposure');
        expect(dbMap['icon'], 'light_icon');
        expect(dbMap['is_active'], 1); // Boolean -> int
        expect(dbMap['created_at'], '2025-01-01T10:00:00.000');
      });

      test('converts isActive false to 0', () {
        final module = Module(
          id: 'inactive',
          name: 'inactive',
          displayName: 'Inactive Module',
          isActive: false, // FALSE
          createdAt: testCreated,
        );

        final dbMap = module.toDatabase();

        expect(dbMap['is_active'], 0);
      });

      test('handles null optional fields correctly', () {
        final module = Module(
          id: 'minimal',
          name: 'minimal',
          displayName: 'Minimal',
          // description and icon are null
          isActive: true,
          createdAt: testCreated,
        );

        final dbMap = module.toDatabase();

        expect(dbMap['description'], isNull);
        expect(dbMap['icon'], isNull);
      });
    });

    group('JSON serialization', () {
      test('toJson and fromJson round-trip', () {
        final json = sampleModule.toJson();
        final restored = Module.fromJson(json);

        expect(restored.id, sampleModule.id);
        expect(restored.name, sampleModule.name);
        expect(restored.displayName, sampleModule.displayName);
        expect(restored.description, sampleModule.description);
        expect(restored.icon, sampleModule.icon);
        expect(restored.isActive, sampleModule.isActive);
      });

      test('handles null optional fields in JSON', () {
        final module = Module(
          id: 'test',
          name: 'test',
          displayName: 'Test Module',
          isActive: true,
          createdAt: testCreated,
        );

        final json = module.toJson();
        final restored = Module.fromJson(json);

        expect(restored.description, isNull);
        expect(restored.icon, isNull);
      });
    });
  });
}
