# Moon Phase Provider Implementation

## Overview

The Moon Phase provider displays the current lunar phase based on the date. It calculates the moon phase using the synodic month cycle and provides information about the moon age, illumination percentage, phase name, and upcoming events (next new moon and next full moon).

## Implementation Details

### Provider File: `lib/providers/provider_moonphase.dart`

### Model: `MoonPhaseModel`

The model calculates moon phase based on:
- **Synodic Month**: 29.53058867 days (the time between successive new moons)
- **Known New Moon**: January 6, 2000 at 18:14 UTC (used as reference point)

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `isInitialized` | `bool` | Whether the model has been initialized |
| `currentDate` | `DateTime` | The date being analyzed |
| `moonAge` | `double` | Days since the last new moon (0-29.53) |
| `illumination` | `double` | Illumination percentage (0-100%) |
| `phaseName` | `String` | Human-readable phase name |
| `phaseEmoji` | `String` | Unicode emoji representing the phase |
| `nextNewMoon` | `DateTime` | Estimated date of next new moon |
| `nextFullMoon` | `DateTime` | Estimated date of next full moon |

#### Phase Names and Emojis

| Phase | Emoji | Position in Cycle |
|-------|-------|-------------------|
| New Moon | 🌑 | 0-3%, 97-100% |
| Waxing Crescent | 🌒 | 3-22% |
| First Quarter | 🌓 | 22-28% |
| Waxing Gibbous | 🌔 | 28-47% |
| Full Moon | 🌕 | 47-53% |
| Waning Gibbous | 🌖 | 53-72% |
| Last Quarter | 🌗 | 72-78% |
| Waning Crescent | 🌘 | 78-97% |

#### Methods

| Method | Description |
|--------|-------------|
| `init()` | Initialize the model and calculate moon phase for current date |
| `refresh()` | Recalculate moon phase and notify listeners |
| `setDate(DateTime)` | Set a specific date to analyze |
| `formatDaysUntil(DateTime)` | Format days until target event (Today, Tomorrow, X days, X weeks, X months) |
| `formatDate(DateTime)` | Format date as MM/DD/YYYY |

### Widget: `MoonPhaseCard`

The card displays:
- Moon phase emoji and name
- Illumination percentage
- Day of cycle
- Date selector with calendar picker
- "Today" quick action button
- Upcoming events section showing next new moon and full moon

### UI Components

- **Phase Display**: Large emoji with phase name and statistics
- **Date Selector**: Current date with calendar picker button
- **Upcoming Events**: Next new moon and full moon countdowns
- **ActionChip**: "Today" button to reset to current date

### Material 3 Components Used

- `Card.filled()` - Main card container
- `Card()` with `surfaceContainerHighest` color - Sub-sections
- `ActionChip` - Today button
- `Icon` with `nightlight_round` - Moon icon
- `showDatePicker()` - Date picker dialog

## Algorithm

### Moon Age Calculation

1. Calculate days since the known new moon (January 6, 2000)
2. Divide by synodic month to get moon cycles
3. Take modulo 1 to get position in current cycle
4. Multiply by synodic month to get moon age

### Illumination Calculation

The illumination is calculated using the formula:
```
angle = (moonAge / synodicMonth) * 2 * π
illumination = (1 - cos(angle)) / 2
```

This gives the fraction of the moon's face that is illuminated.

## Testing

Tests are located in `test/widget_test.dart` under the `MoonPhase provider tests` group:

- Provider existence in Global.providerList
- Model initialization
- Moon age calculation (0-29.53 days)
- Illumination percentage (0-100%)
- Phase name validity (8 valid phases)
- Phase emoji validity (8 valid emojis)
- Next new moon calculation
- Next full moon calculation
- setDate functionality
- refresh notifies listeners
- formatDaysUntil formatting
- formatDate formatting
- Known new moon date calculation
- Full moon timing validation
- Widget rendering (loading and initialized states)

Total tests: 27 tests for MoonPhase provider

## Keywords

The provider registers keywords for search:
- moon, phase, lunar, cycle, full, new, crescent, gibbous, waxing, waning, quarter

## Integration

The provider is integrated into the app through:
- `lib/data.dart`: Import and provider list registration
- `lib/main.dart`: Import and MultiProvider registration

## Usage Example

Users can:
1. View the current moon phase with emoji and illumination percentage
2. See the day of the lunar cycle
3. Select a different date to see past/future moon phases
4. Check upcoming new moon and full moon events
5. Quickly reset to today's date with the "Today" button