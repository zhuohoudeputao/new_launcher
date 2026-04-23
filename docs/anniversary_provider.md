# Anniversary Provider Implementation

## Overview

The Anniversary provider allows users to track recurring events like birthdays, anniversaries, holidays, and other events that repeat yearly. It shows the days until the next occurrence and optionally tracks the number of years since the original date.

## Implementation Details

### File Location
- `lib/providers/provider_anniversary.dart`

### Model: AnniversaryModel

The `AnniversaryModel` class manages anniversary data:

```dart
class AnniversaryModel extends ChangeNotifier {
  List<AnniversaryEntry> _anniversaries = [];
  static const int maxAnniversaries = 15;
  static const String _anniversariesKey = 'Anniversary.List';
  SharedPreferences? _prefs;
  bool _isInitialized = false;
}
```

### AnniversaryEntry Class

Each anniversary entry contains:
- `name`: Event name (e.g., "Mom's Birthday")
- `month`: Month of the event (1-12)
- `day`: Day of the event (1-31)
- `year`: Optional starting year (for age/years tracking)
- `createdAt`: Creation timestamp

```dart
class AnniversaryEntry {
  final String name;
  final int month;
  final int day;
  final int? year;
  final DateTime createdAt;
}
```

### Key Features

1. **Add Anniversary**: Users can add anniversaries with name, month, day, and optional year
2. **Edit Anniversary**: Users can modify all anniversary fields
3. **Delete Anniversary**: Individual anniversaries can be removed
4. **Clear All**: All anniversaries can be cleared with confirmation
5. **Persistence**: Anniversaries are saved via SharedPreferences
6. **Year Tracking**: Optional year field shows age/years count
7. **Time Display**: Days until next shown in human-readable format

### Time Formatting

The model provides:
- `getNextOccurrence()`: Returns the next occurrence date
- `getDaysUntilNext()`: Returns days until next occurrence
- `getOccurrences()`: Returns years count if year is set, null otherwise
- `formatDaysUntil(entry)`: Human-readable format

Format examples:
- "Today!" - for today
- "Tomorrow" - for tomorrow
- "X days" - for days < 7
- "X weeks" - for days < 30
- "X months" - for days < 365
- "X days" - for longer periods

### UI Components

#### AnniversaryCard
- Card.filled Material 3 style
- Title with add/clear buttons
- Empty state message
- ListView of anniversary items

#### Anniversary Item Display
- Icon based on urgency (cake, celebration, event)
- Color coding for today (celebration color)
- Days until next display
- Year count if available
- Tap to edit functionality

#### AddAnniversaryDialog
- Name input field
- Date picker (month and day)
- Year toggle for age tracking
- Material 3 styling

#### EditAnniversaryDialog
- Same fields as add dialog
- Delete button
- Save button

### Keywords

The provider registers keywords for search:
- anniversary, birthday, recurring, event, date, add

### Provider Registration

The provider is registered in `Global.providerList`:
```dart
static List<MyProvider> providerList = [
  // ... other providers
  providerAnniversary,
];
```

## Test Coverage

Tests include:
- Provider existence and keywords
- Model initialization
- CRUD operations (add, update, delete)
- Max anniversary limit (15)
- Persistence via SharedPreferences
- Next occurrence calculation
- Days until calculation
- Years/occurrences count
- Time formatting
- JSON serialization/deserialization
- Widget rendering (loading state, empty state, with items)

Total tests: 27 anniversary-specific tests

## Usage Example

```dart
// Add an anniversary with year tracking
anniversaryModel.addAnniversary('Mom\'s Birthday', 6, 15, 1965);

// Add without year tracking
anniversaryModel.addAnniversary('Wedding Anniversary', 12, 25, null);

// Get days until next
final days = entry.getDaysUntilNext();
print(days); // 30

// Get years count (if year is set)
final years = entry.getOccurrences();
print(years); // 31

// Format for display
final formatted = anniversaryModel.formatDaysUntil(entry);
print(formatted); // "30 days"
```

## Integration

The Anniversary provider integrates with:
- SharedPreferences for persistence
- Provider package for state management
- Material 3 design system for UI
- Global.infoModel for card display