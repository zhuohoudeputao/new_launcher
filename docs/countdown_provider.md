# Countdown Provider Implementation

## Overview

The Countdown provider allows users to track countdowns to important dates such as birthdays, vacations, deadlines, and other events. Users can add, edit, and delete countdowns with the remaining time displayed in a user-friendly format.

## Implementation Details

### File Location
- `lib/providers/provider_countdown.dart`

### Model: CountdownModel

The `CountdownModel` class manages countdown data:

```dart
class CountdownModel extends ChangeNotifier {
  List<CountdownEntry> _countdowns = [];
  static const int maxCountdowns = 10;
  static const String _countdownsKey = 'Countdown.List';
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  Timer? _timer;
  bool _disposed = false;
}
```

### CountdownEntry Class

Each countdown entry contains:
- `name`: Event name
- `targetDate`: Target date/time
- `createdAt`: Creation timestamp

```dart
class CountdownEntry {
  final String name;
  final DateTime targetDate;
  final DateTime createdAt;
}
```

### Key Features

1. **Add Countdown**: Users can add countdowns with a name and target date
2. **Edit Countdown**: Users can modify countdown name and date
3. **Delete Countdown**: Individual countdowns can be removed
4. **Clear All**: All countdowns can be cleared with confirmation
5. **Persistence**: Countdowns are saved via SharedPreferences
6. **Time Display**: Remaining time shown in human-readable format

### Time Formatting

The model provides multiple formatting methods:
- `formatRemainingTime(entry)`: Short format (e.g., "5d 3h")
- `formatDetailedRemainingTime(entry)`: Long format (e.g., "5 days, 3h 15m")
- Expired countdowns show "Expired" or "Event has passed"

### Timer Updates

The model uses a Timer to update the display:
- Initial delay to align with the next minute
- Periodic updates every minute
- Proper disposal handling to prevent setState after dispose

### UI Components

#### CountdownCard
- Card.filled Material 3 style
- Title with add button
- Empty state message
- ListView of countdown items

#### Countdown Item Display
- Icon based on urgency (event, event_busy, event_available)
- Color coding for expired events
- Remaining time display
- Tap to edit functionality

#### AddCountdownDialog
- Name input field
- Date picker
- Optional time picker toggle
- Material 3 styling

#### EditCountdownDialog
- Same fields as add dialog
- Delete button
- Save button

### Keywords

The provider registers keywords for search:
- countdown, deadline, birthday, event, date, add

### Provider Registration

The provider is registered in `Global.providerList`:
```dart
static List<MyProvider> providerList = [
  // ... other providers
  providerCountdown,
];
```

## Test Coverage

Tests include:
- Provider existence and keywords
- Model initialization
- CRUD operations (add, update, delete)
- Max countdown limit (10)
- Persistence via SharedPreferences
- Time calculations (getRemainingTime, isExpired)
- Time formatting
- Widget rendering (loading state, initialized state)

Total tests: 22 countdown-specific tests

## Usage Example

```dart
// Add a countdown
countdownModel.addCountdown('Birthday', DateTime(2026, 12, 25));

// Get remaining time
final remaining = countdownModel.getRemainingTime(entry);
print(remaining.inDays); // Days until event

// Format for display
final formatted = countdownModel.formatRemainingTime(entry);
print(formatted); // "5d 3h"
```

## Integration

The Countdown provider integrates with:
- SharedPreferences for persistence
- Provider package for state management
- Material 3 design system for UI
- Global.infoModel for card display