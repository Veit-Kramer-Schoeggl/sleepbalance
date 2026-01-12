# Migration V2: Daily Actions Table

**Version:** 2
**Status:** ✅ Active
**Purpose:** Adds Action Center feature support

## Overview

Migration V2 introduces the `daily_actions` table to support the Action Center feature. This table allows users to track daily habits and tasks with completion status, providing a simple way to manage sleep-related actions.

## Tables Created

### `daily_actions`

Stores user's daily action items (tasks/habits) with date-based tracking and completion status.

**Columns:**

| Column | Type | Constraints | Description |
|--------|------|------------|-------------|
| `id` | TEXT | PRIMARY KEY | UUID for action item |
| `user_id` | TEXT | NOT NULL, FK → users(id) | User who owns this action |
| `title` | TEXT | NOT NULL | Action item text (e.g., "Morning sunlight") |
| `icon_name` | TEXT | NOT NULL | Icon identifier for UI display |
| `is_completed` | INTEGER | NOT NULL DEFAULT 0 | Boolean: action completed today |
| `action_date` | TEXT | NOT NULL | The day this action is for (DATE format) |
| `created_at` | TEXT | NOT NULL | When action was created |
| `completed_at` | TEXT | | When user marked it complete (TIMESTAMP) |

**Constraints:**
- `FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE`

**Indexes:**
- `idx_daily_actions_user_date` on `(user_id, action_date)` - Fast lookups for "today's actions"

## Use Cases

1. **Daily Habit Tracking:**
   - User creates custom daily tasks (e.g., "Take magnesium supplement")
   - Can check off items throughout the day
   - Track completion history over time

2. **Action Center UI:**
   - Display list of today's actions
   - Filter by completion status
   - Show completion streaks

3. **Future Integration:**
   - Will integrate with module reminder system
   - Module interventions can create action items automatically
   - Example: Light module creates "Get 30min morning sunlight" action

## Example Data

```sql
INSERT INTO daily_actions VALUES
  ('uuid1', 'user123', 'Get morning sunlight', 'wb_sunny', 1, '2025-10-29', '2025-10-29 06:00:00', '2025-10-29 07:30:00'),
  ('uuid2', 'user123', 'Evening meditation', 'self_improvement', 0, '2025-10-29', '2025-10-29 06:00:00', NULL),
  ('uuid3', 'user123', 'No caffeine after 2pm', 'no_drinks', 1, '2025-10-29', '2025-10-29 06:00:00', '2025-10-29 14:30:00');
```

## Migration Script Location

`lib/core/database/migrations/migration_v2.dart`

## Applied

This migration is applied during:
- Fresh database creation (version 2+)
- Upgrade from version 1 to version 2+

## Notes

- Simple design: focused on core functionality (title, completion status, date)
- Icon-based UI for better visual engagement
- Date-based tracking allows historical analysis of habit adherence
- Future: Could add `priority`, `category`, or `module_id` fields
- Future: Could track completion streaks in a separate analytics table
