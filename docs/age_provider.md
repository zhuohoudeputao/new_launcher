# Age Calculator Provider

## Overview

The Age Calculator provider allows users to calculate age from a birthdate. It displays age in years, months, and days, along with zodiac sign information and days until the next birthday.

## Features

- Calculate age from birthdate in years, months, and days
- Display total days lived
- Zodiac sign (Western) with emoji indicators
- Chinese zodiac with emoji indicators
- Days until next birthday countdown
- Birthday proximity indicator (warning color if birthday is within 7 days)
- Save multiple birthdates for quick reference (up to 10 entries)
- Load saved birthdates to quickly recalculate
- Delete individual entries or clear all entries

## Implementation Details

### Location
- Provider file: `lib/providers/provider_age.dart`
- Provider name: `providerAge`
- Model: `ageModel` (AgeModel class)

### Provider Pattern

```dart
MyProvider providerAge = MyProvider(
  name: "Age",
  provideActions: _provideActions,
  initActions: _initActions,
  update: _update,
);
```

### AgeEntry Class

Stores saved birthdate information:
- `name`: Display name for the entry
- `birthdate`: The birthdate
- `createdAt`: Timestamp when entry was created

### AgeModel Class

Extends `ChangeNotifier` and provides:

**Properties:**
- `birthdate`: Current selected birthdate
- `savedEntries`: List of saved birthdate entries
- `hasBirthdate`: Boolean indicating if a birthdate is set
- `hasSavedEntries`: Boolean indicating if there are saved entries
- `isInitialized`: Initialization state

**Methods:**
- `getZodiacSign(DateTime date)`: Returns Western zodiac sign with emoji
- `getChineseZodiac(DateTime date)`: Returns Chinese zodiac sign with emoji
- `calculateAgeYears(DateTime birthdate)`: Calculates age in years
- `calculateAgeMonths(DateTime birthdate)`: Calculates age in months
- `calculateAgeDays(DateTime birthdate)`: Calculates total days lived
- `calculateDaysUntilNextBirthday(DateTime birthdate)`: Days until next birthday
- `formatAge(DateTime birthdate)`: Formats age as "X years, Y months"
- `formatAgeDetailed(DateTime birthdate)`: Detailed format with total days
- `setBirthdate(DateTime date)`: Sets the current birthdate
- `saveEntry(String name)`: Saves current birthdate with a name
- `loadEntry(AgeEntry entry)`: Loads a saved entry
- `deleteEntry(int index)`: Deletes a saved entry
- `clearAllEntries()`: Clears all saved entries
- `clear()`: Clears current birthdate

### Zodiac Signs

**Western Zodiac (with emojis):**
- Aries ♈ (Mar 21 - Apr 19)
- Taurus ♉ (Apr 20 - May 20)
- Gemini ♊ (May 21 - Jun 20)
- Cancer ♋ (Jun 21 - Jul 22)
- Leo ♌ (Jul 23 - Aug 22)
- Virgo ♍ (Aug 23 - Sep 22)
- Libra ♎ (Sep 23 - Oct 22)
- Scorpio ♏ (Oct 23 - Nov 21)
- Sagittarius ♐ (Nov 22 - Dec 21)
- Capricorn ♑ (Dec 22 - Jan 19)
- Aquarius ♒ (Jan 20 - Feb 18)
- Pisces ♓ (Feb 19 - Mar 20)

**Chinese Zodiac (with emojis):**
Cycle of 12 animals based on birth year:
- Rat 🐀, Ox 🐂, Tiger 🐅, Rabbit 🐇, Dragon 🐲, Snake 🐍
- Horse 🐎, Goat 🐐, Monkey 🐒, Rooster 🐓, Dog 🐕, Pig 🐖

### UI Components

**AgeCard Widget:**
- Card.filled for Material 3 style
- Shows empty state when no birthdate selected
- Displays age result with large year number
- Shows zodiac signs in two-row layout
- Birthday countdown indicator with color coding
- Save button to store entries
- Clear button to reset
- History button to view saved entries

**History Dialog:**
- Lists saved birthdate entries
- Shows age and birthdate for each entry
- Tap to load entry
- Delete button for each entry
- Clear all button with confirmation

### Data Persistence

- Uses SharedPreferences for storage
- Key: `age_birthdate` for current birthdate
- Key: `age_saved_entries` for saved entries list
- Maximum 10 saved entries (oldest removed when exceeded)
- JSON serialization for AgeEntry objects

## Keywords

`age birthday birthdate calculate years old zodiac`

## Integration

### In data.dart

```dart
import 'package:new_launcher/providers/provider_age.dart';
// ...
static List<MyProvider> providerList = [
  // ...
  providerAge,
];
```

### In main.dart

```dart
import 'package:new_launcher/providers/provider_age.dart';
// ...
MultiProvider(
  providers: [
    // ...
    ChangeNotifierProvider.value(value: ageModel),
  ],
)
```

## Material 3 Design

- Uses `Card.filled` for consistent card styling
- Primary container color for age display
- Color-coded birthday countdown (error color for <= 7 days)
- SegmentedButton would be used for unit selection (if needed)
- IconButton.styleFrom for consistent icon styling
- FilledButton for save action

## Testing

Tests cover:
- AgeModel initialization
- Zodiac sign calculation (Western and Chinese)
- Age calculation in years, months, days
- Days until next birthday calculation
- Age formatting methods
- Birthdate setting and clearing
- Entry saving, loading, and deletion
- Maximum entry limit enforcement
- Provider existence and keywords
- AgeCard widget rendering (loading, initialized, empty states)
- AgeEntry JSON serialization

Total: 29 tests for Age provider

## Usage Examples

1. **Calculate Age:**
   - Tap calendar button to select birthdate
   - Age is automatically calculated and displayed

2. **Save Birthdate:**
   - Enter a name in the text field
   - Tap save button to add to saved entries

3. **Load Saved Entry:**
   - Tap history button
   - Tap on an entry to load it

4. **View Zodiac Signs:**
   - Both Western and Chinese zodiac signs are displayed automatically

5. **Track Birthday:**
   - Days until next birthday shown with countdown
   - Special indicator when birthday is within 7 days
   - Celebration message on birthday day

## Related Providers

- **Anniversary**: For tracking recurring events like birthdays
- **Countdown**: For countdown to specific dates
- **Calendar**: For viewing the current month

The Age Calculator complements Anniversary by providing quick age calculation and zodiac information, while Anniversary tracks the recurring nature of birthday events.