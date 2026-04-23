# Habit Tracker Provider

## Overview

The Habit Tracker provider allows users to track daily habits with streak tracking. Users can add, edit, and delete habits, mark them as complete for the day, and track their progress over time.

## Features

- **Daily habit tracking**: Mark habits as completed for each day
- **Streak tracking**: Track consecutive days of completion
- **Best streak record**: Store the highest streak achieved
- **Quick completion**: Tap to toggle habit completion
- **Daily reset**: Streaks reset if not completed the previous day
- **Maximum 10 habits**: Prevents overcrowding

## Implementation

### Provider File

Located at `lib/providers/provider_habit.dart`.

### Key Components

1. **HabitModel**: Manages habit data and state
   - `habits`: List of habit items
   - `length`: Number of habits
   - `completedTodayCount`: Count of habits completed today
   - `isInitialized`: Initialization state

2. **HabitItem**: Data model for individual habits
   - `name`: Habit name
   - `streak`: Current streak count
   - `bestStreak`: Highest streak achieved
   - `completedDates`: Set of dates completed (YYYY-MM-DD format)
   - `createdAt`: Creation timestamp

3. **HabitCard**: UI widget displaying all habits
   - Shows completion count for today
   - Tap to toggle completion
   - Long press to edit
   - Fire icon with streak number
   - Color coding for streak levels (7+ days, 3-6 days, <3 days)

4. **AddHabitDialog**: Dialog for adding new habits
5. **EditHabitDialog**: Dialog for editing/deleting habits

### Keywords

```
habit, track, daily, routine, streak, goal, habit tracker
```

### Storage

Habits are persisted via SharedPreferences with key `habit_items`.

### Daily Reset Logic

The provider automatically checks and resets streaks:
- If today's date is not in completedDates and yesterday's date is also not in completedDates, the streak resets to 0
- This ensures streaks only count consecutive days

## UI Components

### HabitCard Layout

```
Habit Tracker                    X/10 today
────────────────────────────────────────────
☑ Exercise                🔥 7  (green)
☐ Read                    🔥 3  (yellow)
○ Meditate                🔥 0  (gray)
────────────────────────────────────────────
[+] Add                    [🗑] Clear all
```

### Streak Colors

- **Primary color** (green): Streak >= 7 days
- **Tertiary color** (yellow): Streak >= 3 days
- **OnSurface with opacity** (gray): Streak < 3 days

## Usage

1. **Add habit**: Tap the + button, enter habit name
2. **Mark complete**: Tap on the habit row
3. **Edit habit**: Long press on the habit row
4. **Delete habit**: Long press, then tap Delete in dialog
5. **Clear all**: Tap the delete sweep button, confirm in dialog

## Testing

Tests cover:
- Model initialization
- Habit CRUD operations
- Toggle completion logic
- Streak tracking
- Best streak updates
- Max habit limit
- Widget rendering
- Provider registration

## Integration

The Habit provider is registered in:
- `lib/main.dart`: MultiProvider registration
- `lib/data.dart`: Global.providerList

## Material 3 Components

- `Card.filled`: Main card container
- `Card` with surfaceContainerHighest: Habit items
- `Icon`: check_circle, circle_outlined, track_changes, local_fire_department
- `IconButton`: Add and delete sweep buttons
- `AlertDialog`: Add/Edit/Clear confirm dialogs
- `SelectableText`: Habit names (not used, just Text)

## Future Enhancements

Potential improvements:
- Weekly/monthly statistics
- Habit categories
- Reminder notifications
- Export/import habits
- Custom habit icons