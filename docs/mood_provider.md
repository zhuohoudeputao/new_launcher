# Mood Tracker Provider

## Overview

The Mood provider allows users to track their daily mood and emotional well-being. It provides a simple emoji-based interface for logging mood levels and tracks mood history with statistics for positive streaks and average mood.

## Implementation

### File Location
`lib/providers/provider_mood.dart`

### Model: `MoodModel`

The `MoodModel` class manages the state for mood tracking:

```dart
class MoodModel extends ChangeNotifier {
  static const int maxHistoryDays = 30;
  static const String _storageKey = 'mood_entries';

  List<MoodEntry> _history = [];
  bool _isInitialized = false;
}
```

### Properties

- `isInitialized`: Whether the model has been initialized
- `history`: List of mood entries for the past 30 days
- `todayMood`: Current day's mood level (null if not logged)
- `positiveStreak`: Count of consecutive days with positive/neutral mood
- `mostCommonMood`: The most frequently logged mood level
- `averageMood`: Average mood value across all entries

### Methods

- `init()`: Initialize model and load saved data from SharedPreferences
- `logMood(MoodLevel mood, {String? note})`: Log mood for today
- `clearHistory()`: Clear all mood history entries
- `refresh()`: Refresh model state

### Mood Levels: `MoodLevel` enum

```dart
enum MoodLevel {
  verySad,   // value: 1, emoji: 😢
  sad,       // value: 2, emoji: 😔
  neutral,   // value: 3, emoji: 😐
  happy,     // value: 4, emoji: 😊
  veryHappy, // value: 5, emoji: 😄
}
```

### Data Structure: `MoodEntry`

```dart
class MoodEntry {
  final DateTime date;
  final int moodValue;
  final String? note;

  MoodLevel get mood;
  String toJson();
  static MoodEntry fromJson(String jsonStr);
  static String getDayKey(DateTime date);
}
```

## UI Components

### MoodCard

The main widget displays:
- Title with mood icon
- Today's mood with emoji and label (if logged)
- "No mood logged today" message (if not logged)
- Positive streak count with fire icon
- Average mood value
- Log/Update mood button
- History button (when history exists)

### MoodPickerSheet

Bottom sheet for mood selection:
- "How are you feeling?" header
- Five mood options with emojis and labels
- Each option has color-coded background
- Tap to log and close sheet

### History Dialog

Shows mood history:
- List of entries sorted by date (most recent first)
- Each entry shows emoji, label, and date
- Close button
- Clear all button (with confirmation)

## Features

### Mood Logging
- Five mood levels from Very Sad to Very Happy
- Emoji-based visual representation
- Optional note field for context
- Updates existing entry if logged twice today

### Statistics
- Positive streak: Counts consecutive days with mood >= neutral (value 3)
- Most common mood: Most frequently logged mood
- Average mood: Mean value across all entries

### Persistence
- All data saved to SharedPreferences
- History entries serialized as JSON
- History limited to 30 days

### Daily Tracking
- One entry per day
- Automatic update when logging again on same day
- Entry created on first log for each day

## Material 3 Compliance

- Uses `Card.filled` for main card container
- Uses `Theme.of(context).cardColor` for transparency support
- Uses ColorScheme colors for mood indication
- Uses `TextButton.icon` for consistent button styling
- Uses `showModalBottomSheet` for mood picker

## Provider Registration

```dart
MyProvider providerMood = MyProvider(
    name: "Mood",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

Added to `Global.providerList` in `lib/data.dart`.

## Keywords

Keywords for search functionality:
- mood
- emotion
- feeling
- happy
- sad
- track
- daily
- mental
- health

## Testing

Tests are located in `test/widget_test.dart` under the "Mood provider tests" group:

- MoodModel initialization
- MoodLevel values, emojis, labels
- MoodLevelExtension.fromValue
- MoodEntry JSON serialization
- MoodEntry getDayKey
- MoodModel logMood operations
- MoodModel positiveStreak calculation
- MoodModel mostCommonMood calculation
- MoodModel averageMood calculation
- MoodModel clearHistory
- MoodCard widget rendering
- MoodPickerSheet widget existence
- Provider registration verification

## Usage Example

```dart
// Log a happy mood
moodModel.logMood(MoodLevel.happy);

// Log a mood with a note
moodModel.logMood(MoodLevel.veryHappy, note: 'Great day at work!');

// Check positive streak
if (moodModel.positiveStreak >= 7) {
  // Celebrate week of positive mood
}

// Get average mood
final avg = moodModel.averageMood;

// Clear history
await moodModel.clearHistory();
```

## Future Enhancements

Potential improvements:
- Time-based mood logging (morning, afternoon, evening)
- Weekly/monthly mood charts
- Mood trend analysis
- Reminder notifications
- Export mood data
- Integration with journal/notes