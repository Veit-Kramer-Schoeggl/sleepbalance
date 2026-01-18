import 'package:flutter/material.dart';

/// Metadata describing an intervention module
///
/// Contains display information used by UI to show modules to users.
/// This is hardcoded configuration data, not database models.
class ModuleMetadata {
  /// Unique module identifier (matches module_id in database)
  final String id;

  /// Display name shown to users
  final String displayName;

  /// Short description (1-2 sentences) for module selection
  final String shortDescription;

  /// Longer description explaining module benefits and usage
  final String longDescription;

  /// Icon representing the module
  final IconData icon;

  /// Primary color for module UI elements
  final Color primaryColor;

  /// Whether module is currently implemented
  /// Set to false for planned modules not yet available
  final bool isAvailable;

  const ModuleMetadata({
    required this.id,
    required this.displayName,
    required this.shortDescription,
    required this.longDescription,
    required this.icon,
    required this.primaryColor,
    this.isAvailable = true,
  });
}

/// Central registry of all module metadata
///
/// Add new modules here when implementing them.
/// UI will automatically display new modules when added to this map.
const Map<String, ModuleMetadata> moduleMetadata = {
  'light': ModuleMetadata(
    id: 'light',
    displayName: 'Light Therapy',
    shortDescription: 'Morning bright light to regulate circadian rhythm',
    longDescription: 'Optimize light exposure throughout the day to support '
        'healthy circadian rhythms and improve sleep quality. Bright light '
        'in the morning advances the sleep-wake cycle, while avoiding bright '
        'light in the evening supports natural melatonin production.',
    icon: Icons.wb_sunny,
    primaryColor: Color(0xFFFFA726), // Amber
    isAvailable: true,
  ),

  'sport': ModuleMetadata(
    id: 'sport',
    displayName: 'Physical Activity',
    shortDescription: 'Exercise timing and intensity optimization',
    longDescription: 'Track exercise timing and intensity with wearable '
        'integration. Morning HIIT provides optimal sleep benefit, while '
        'high-intensity evening exercise may disrupt sleep. Find your '
        'optimal exercise schedule.',
    icon: Icons.directions_run,
    primaryColor: Color(0xFF66BB6A), // Green
    isAvailable: true, // Available in MVP (basic UI and logic, no advanced features yet)
  ),

  'meditation': ModuleMetadata(
    id: 'meditation',
    displayName: 'Meditation & Relaxation',
    shortDescription: 'Guided relaxation and breathwork practices',
    longDescription: 'Access a library of guided meditation and breathwork '
        'sessions. Evening pre-sleep sessions reduce anxiety and racing '
        'thoughts. Diverse techniques from multiple teachers and traditions.',
    icon: Icons.spa,
    primaryColor: Color(0xFF9C27B0), // Purple
    isAvailable: true, // Available in MVP (basic UI and logic, no advanced features yet)
  ),

  'temperature': ModuleMetadata(
    id: 'temperature',
    displayName: 'Temperature Therapy',
    shortDescription: 'Cold and heat exposure for sleep enhancement',
    longDescription: 'Optimize temperature exposure timing. Morning cold '
        'showers boost alertness, while evening saunas facilitate sleep '
        'onset through subsequent body cooling. Science-backed protocols.',
    icon: Icons.thermostat,
    primaryColor: Color(0xFF42A5F5), // Blue
    isAvailable: false,
  ),

  'mealtime': ModuleMetadata(
    id: 'mealtime',
    displayName: 'Meal Timing',
    shortDescription: 'Eating schedule optimization for better sleep',
    longDescription: 'Optimize eating windows and meal timing. Default '
        '3-meal pattern or customizable intermittent fasting windows, '
        'automatically adjusted to your sleep schedule.',
    icon: Icons.restaurant_menu,
    primaryColor: Color(0xFFFF7043), // Deep Orange
    isAvailable: false,
  ),

  'nutrition': ModuleMetadata(
    id: 'nutrition',
    displayName: 'Sleep Nutrition',
    shortDescription: 'Evidence-based food and supplement guidance',
    longDescription: 'Learn about sleep-promoting foods, nutrients, and '
        'supplements. Daily tips, comprehensive food database, and '
        'personalized recommendations based on dietary preferences.',
    icon: Icons.eco,
    primaryColor: Color(0xFF26A69A), // Teal
    isAvailable: false,
  ),

  'journaling': ModuleMetadata(
    id: 'journaling',
    displayName: 'Sleep Journaling',
    shortDescription: 'Reflective writing with pattern recognition',
    longDescription: 'Track thoughts, emotions, and daily events with '
        'multiple input methods (typing, voice, handwriting). ML-based '
        'pattern recognition identifies factors affecting your sleep.',
    icon: Icons.edit_note,
    primaryColor: Color(0xFF8D6E63), // Brown
    isAvailable: false,
  ),
};

/// Get metadata for a specific module
///
/// Returns unknown module metadata if module_id not found.
/// This prevents crashes when referencing modules not yet defined.
ModuleMetadata getModuleMetadata(String moduleId) {
  return moduleMetadata[moduleId] ??
      const ModuleMetadata(
        id: 'unknown',
        displayName: 'Unknown Module',
        shortDescription: 'Module not found',
        longDescription: '',
        icon: Icons.help_outline,
        primaryColor: Color(0xFF9E9E9E), // Grey
        isAvailable: false,
      );
}

/// Get all available (implemented) modules
List<ModuleMetadata> getAvailableModules() {
  return moduleMetadata.values.where((m) => m.isAvailable).toList();
}

/// Get all planned (not yet implemented) modules
List<ModuleMetadata> getPlannedModules() {
  return moduleMetadata.values.where((m) => !m.isAvailable).toList();
}

/// Get all modules (implemented + planned)
List<ModuleMetadata> getAllModules() {
  return moduleMetadata.values.toList();
}
