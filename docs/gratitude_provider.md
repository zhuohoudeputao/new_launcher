# Gratitude Provider

## Overview

The Gratitude provider is a daily gratitude journal for mental health tracking. It allows users to record what they're grateful for each day, track streaks for consecutive days of gratitude logging, and view their gratitude history.

## Features

- **Daily Entries**: Record up to 5 gratitude entries per day
- **Streak Tracking**: Track consecutive days of gratitude logging
- **History View**: View past gratitude entries with expandable day entries
- **Delete Entries**: Remove individual entries via history view
- **Clear History**: Clear all history with confirmation dialog
- **Persistence**: All entries stored via SharedPreferences
- **Visual Appeal**: Heart icon with pink color theme

## Implementation Details

### Data Models

#### GratitudeEntry
- `date`: DateTime of the entry
- `text`: String content of the gratitude entry
- Methods: `toJson()`, `fromJson()`, `getDayKey()`

#### GratitudeDay
- `date`: DateTime of the day
- `entries`: List of GratitudeEntry for that day
- Methods: `toJson()`, `fromJson()`

#### GratitudeModel
- `maxHistoryDays`: 30 days maximum
- `maxEntriesPerDay`: 5 entries per day maximum
- `_storageKey`: 'gratitude_days'
- Methods:
  - `init()`: Initialize from SharedPreferences
  - `addEntry(text)`: Add a new gratitude entry
  - `removeEntry(entry)`: Remove an existing entry
  - `clearHistory()`: Clear all history
  - Properties:
    - `todayDay`: Current day's GratitudeDay
    - `todayEntries`: List of today's entries
    - `todayCount`: Number of entries today
    - `streak`: Consecutive days count
    - `totalEntries`: Total number of entries across all days

### UI Components

#### GratitudeCard
- Displays gratitude journal summary
- Shows today's entries with heart icons
- Displays streak count with fire icon
- Shows entry count (X/5 entries today)
- Add button (disabled when max entries reached)
- History button (visible when history exists)

#### GratitudeInputDialog
- Modal dialog for adding new gratitude entries
- TextField for entry content
- Cancel and Add buttons

## Keywords

`gratitude, grateful, thanks, thankful, appreciation, journal, daily, positive`

## Material 3 Design

- Uses `Card.filled` for consistent styling
- Pink color for heart icons (`Colors.pink`)
- Orange color for streak fire icon (`Colors.orange`)
- Theme-aware text colors via `Theme.of(context).colorScheme`

## Testing

Tests include:
- Model initialization
- Add/remove entries
- Max entries per day limit
- Streak calculation
- Clear history
- JSON serialization/deserialization
- Widget rendering (loading, empty, with entries)
- Provider existence in Global.providerList

## Storage

Data is persisted via SharedPreferences:
- Key: 'gratitude_days'
- Format: JSON array of GratitudeDay objects