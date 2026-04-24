# Workout Provider Implementation

## Overview

The Workout provider is a fitness tracking feature that allows users to log their exercise sessions with type, duration, and optional notes. It tracks workout history and provides statistics for weekly and monthly totals.

## Features

- **Workout Types**: 8 predefined workout types with emoji indicators:
  - Running (🏃)
  - Cycling (🚴)
  - Weights (🏋️)
  - Yoga (🧘)
  - Swimming (🏊)
  - Walking (🚶)
  - HIIT (⚡)
  - Other (💪)
- **Duration Tracking**: Log workout duration from 5 to 180 minutes
- **Optional Notes**: Add notes for each workout session
- **Custom Date Logging**: Log workouts for past dates (within 30 days)
- **History Tracking**: Up to 100 workout entries stored
- **Statistics Display**:
  - Weekly total minutes
  - Monthly total minutes
  - Total workout minutes
  - Total sessions count
- **History View**: Browse past workouts with delete option
- **Clear All**: Remove all workout history with confirmation

## Implementation Details

### File Structure

- `lib/providers/provider_workout.dart`: Main provider implementation

### Key Classes

#### WorkoutType Enum
Defines 8 workout types with:
- `emoji`: Emoji indicator for visual display
- `label`: Human-readable name
- `getColor()`: Material 3 color for visual styling
- `fromString()`: Parse from JSON string

#### WorkoutEntry Class
Represents a single workout log entry:
- `date`: DateTime of workout
- `type`: WorkoutType enum
- `durationMinutes`: Duration in minutes
- `note`: Optional notes
- `toJson()`/`fromJson()`: JSON serialization for persistence
- `formatDuration()`: Human-readable duration format

#### WorkoutModel Class (ChangeNotifier)
State management for workout data:
- `history`: List of workout entries
- `isInitialized`: Initialization status flag
- `totalMinutes`: Sum of all workout durations
- `thisWeekMinutes`: Minutes from current week
- `thisMonthMinutes`: Minutes from current month
- `thisWeekSessions`: Sessions from current week
- `thisMonthSessions`: Sessions from current month
- `lastEntry`: Most recent workout entry
- `hasHistory`: Boolean for history existence
- `formatTotalMinutes()`: Format minutes for display

### Provider Pattern

The provider follows the standard pattern:

```dart
MyProvider providerWorkout = MyProvider(
  name: "Workout",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);
```

### UI Components

#### WorkoutCard
Main display widget showing:
- Last workout info (type, duration, date)
- Weekly/monthly statistics
- Log and History buttons

#### WorkoutLogDialog
Dialog for logging workouts:
- Workout type selection with visual chips
- Duration slider (5-180 minutes)
- Optional notes input
- Custom date option

## Data Persistence

Workout entries are persisted via SharedPreferences:
- Key: `'workout_entries'`
- Format: List of JSON strings
- Maximum entries: 100 (oldest removed when exceeded)

## Keywords

Searchable keywords for the provider:
- `workout`
- `exercise`
- `gym`
- `fitness`
- `run`
- `cycle`
- `swim`
- `yoga`
- `walk`
- `training`
- `log`

## Material 3 Styling

- Uses `Card.filled` for consistent styling
- Color-coded workout types
- `Wrap` widget for workout type selection
- `Slider` for duration selection
- Statistics display with icons

## Integration

Added to:
- `lib/data.dart`: Import and provider list
- `lib/main.dart`: Import and MultiProvider

## Testing

Tests located in `test/widget_test.dart`:
- WorkoutType enum tests
- WorkoutEntry properties tests
- WorkoutModel state tests
- WorkoutCard widget tests
- Provider integration tests

Total tests: 35 tests for Workout provider