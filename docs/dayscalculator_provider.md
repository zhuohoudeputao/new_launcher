# Days Calculator Provider Implementation

## Overview

The DaysCalculator provider implements a date calculation tool that allows users to:
1. Calculate the number of days between two dates
2. Add days to a date
3. Subtract days from a date

This is different from existing providers:
- **Countdown**: Tracks events with countdown timers
- **Anniversary**: Tracks recurring events (birthdays, holidays)
- **Age**: Calculates age from birthdate with zodiac signs

## Implementation Details

### File Structure

- `lib/providers/provider_dayscalculator.dart` - Main provider implementation
- Model: `DaysCalculatorModel` - State management
- Widget: `DaysCalculatorCard` - UI component

### Model: DaysCalculatorModel

The model manages:
- Operation type: `difference`, `add`, `subtract`
- Start date and end date (for difference calculations)
- Days to add/subtract (for add/subtract operations)
- Calculated results: days, weeks, months, years
- Result date (for add/subtract operations)
- History of calculations (max 10 entries)

Key methods:
- `init()` - Initialize with today's dates
- `setOperation()` - Change operation type
- `setStartDate()`, `setEndDate()` - Set dates
- `setDaysToAdd()` - Set days for add/subtract
- `swapDates()` - Swap start and end dates
- `addToHistory()`, `clearHistory()` - History management
- `reset()` - Reset all values to defaults

### Widget: DaysCalculatorCard

Features:
- SegmentedButton for operation selection (Difference, Add Days, Subtract Days)
- Date picker for selecting dates
- Today button for quick date selection
- Swap dates button (for difference mode)
- Slider for selecting days to add/subtract (0-365)
- Result display with days, weeks, months, years as Chips
- History view with clear option
- Reset button

### Material 3 Components Used

- `Card.filled` - Main card container
- `SegmentedButton` - Operation selector
- `Slider` - Days selection
- `Chip` - Result display
- `InkWell` - Date picker buttons
- `IconButton` with `styleFrom` - Today, swap, reset buttons
- `ElevatedButton` - Add to history button
- `AlertDialog` - Clear history confirmation

## Keywords

The provider is searchable with keywords:
- days, calculator, date, difference, between, add, subtract, calculate

## Testing

Tests cover:
- Provider existence in Global.providerList
- Model initialization
- Operation switching
- Date difference calculations
- Add/subtract days operations
- Swap dates functionality
- Set today functionality
- History management (add, clear, max length)
- Reset functionality
- Listener notifications
- Widget rendering

## Integration

The provider is integrated into the app via:
1. Added to `Global.providerList` in `lib/data.dart`
2. Added to `MultiProvider` in `lib/main.dart`
3. Model exposed as `daysCalculatorModel`

## User Experience

1. User opens the app and sees the Days Calculator card
2. User selects operation type (Difference/Add/Subtract)
3. For difference: select start and end dates, see results
4. For add/subtract: select a date and days amount, see result date
5. User can add calculation to history for reference
6. User can clear history when needed
7. User can reset all inputs to start fresh