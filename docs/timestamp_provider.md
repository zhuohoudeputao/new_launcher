# Timestamp Converter Provider Implementation

## Overview

The Timestamp provider provides Unix timestamp to datetime conversion and vice versa. It allows developers and users to quickly convert timestamps to readable dates and convert datetime strings back to timestamps.

## Implementation Details

### File Location
`lib/providers/provider_timestamp.dart`

### Model Class: `TimestampModel`

The `TimestampModel` class extends `ChangeNotifier` and manages:
- Input value (timestamp or datetime string)
- Input type selection (timestamp/datetime)
- Output value (converted result)
- Error handling
- Conversion history

### Features

1. **Timestamp to Datetime Conversion**
   - Automatically detects milliseconds vs seconds timestamps
   - Timestamps > 1000000000000 are treated as milliseconds
   - Timestamps < 1000000000000 are treated as seconds
   - Uses UTC for consistent results across timezones
   - Output format: `YYYY-MM-DD HH:MM:SS`

2. **Datetime to Timestamp Conversion**
   - Parses datetime strings in format: `YYYY-MM-DD HH:MM:SS`
   - Converts to UTC milliseconds timestamp
   - Handles invalid format gracefully

3. **Current Timestamp**
   - Quick button to use current timestamp
   - Shows current time in milliseconds

4. **Swap Function**
   - One-tap swap between timestamp and datetime input types
   - Automatically transfers converted output to input

5. **History Management**
   - Stores up to 10 conversion entries
   - Preserves input type
   - Timestamps for each entry
   - Tap to reload from history

### UI Components

The `TimestampCard` widget uses Material 3 components:
- `Card.filled` for the main container
- `SegmentedButton` for timestamp/datetime selection
- `TextField` for input with clear button
- `SelectableText` for output display
- `IconButton` for action buttons (swap, current timestamp)

### Keywords for Search

The provider registers actions with keywords:
- `timestamp, unix, datetime, epoch, time, convert, date`

## Provider Registration

1. Added to `Global.providerList` in `lib/data.dart`
2. Added to `MultiProvider` in `lib/main.dart`
3. Model imported in both files

## Testing

The provider includes comprehensive tests covering:
- Model initialization
- Timestamp to datetime conversion (milliseconds and seconds)
- Datetime to timestamp conversion
- Invalid input handling
- Empty input handling
- Swap input type functionality
- Current timestamp functionality
- History management (add, limit, apply from history, clear)
- Input type triggering conversion
- Notification tests
- UI widget rendering
- Provider registration

Total: 25 Timestamp-specific tests

## Usage Example

```dart
final model = TimestampModel();
model.init();

// Convert timestamp to datetime
model.setInputType('timestamp');
model.setInputValue('1609459200000');
// Output: "2021-01-01 00:00:00"

// Convert datetime to timestamp
model.setInputType('datetime');
model.setInputValue('2021-01-01 00:00:00');
// Output: "1609459200000"

// Use current timestamp
model.setCurrentTimestamp();
// Input: current timestamp, Output: current datetime

// Swap input types
model.swapInputType();
// Switches from timestamp to datetime or vice versa
```

## Notes

- Uses UTC timezone for all conversions to ensure consistency
- Handles both milliseconds and seconds timestamps automatically
- Maximum 10 history entries (oldest removed when exceeded)
- No external packages required (uses Dart's built-in DateTime)