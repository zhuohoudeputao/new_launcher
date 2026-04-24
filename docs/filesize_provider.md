# FileSizeConverter Provider

## Overview

The FileSizeConverter provider is a utility for converting file sizes between different units (Bytes, KB, MB, GB, TB, PB). It provides real-time conversion as you type, history tracking, and human-readable size display.

## Features

- **Unit Conversion**: Convert between Bytes, Kilobyte, Megabyte, Gigabyte, Terabyte, and Petabyte
- **Real-time Conversion**: Conversion updates automatically as you type
- **Swap Units**: One-tap button to swap input and output units
- **Human-readable Display**: Shows the converted value in the most appropriate unit
- **Conversion History**: Track up to 10 recent conversions
- **Tap History**: Reuse previous conversions by tapping history entries
- **Clear History**: Confirmation dialog for clearing all history

## Implementation Details

### File Location
- Provider implementation: `lib/providers/provider_filesize.dart`

### Model
`FileSizeConverterModel` extends `ChangeNotifier` and manages:
- Input/output unit selection
- Input value and converted output
- Conversion history (max 10 entries)
- Initialization state

### Units Supported
- **Bytes (B)**: Base unit, multiplier = 1.0
- **Kilobyte (KB)**: multiplier = 1024
- **Megabyte (MB)**: multiplier = 1024²
- **Gigabyte (GB)**: multiplier = 1024³
- **Terabyte (TB)**: multiplier = 1024⁴
- **Petabyte (PB)**: multiplier = 1024⁵

### Key Methods

```dart
// Convert file size between units
static double convertFileSize(double value, SizeUnit fromUnit, SizeUnit toUnit)

// Get human-readable size string
String getHumanReadableSize(double bytes)

// Swap input and output units
void swapUnits()

// Add current conversion to history
void addToHistory()

// Clear all history
void clearHistory()

// Use a history entry
void useHistoryEntry(ConversionHistoryEntry entry)
```

### UI Components
- `FileSizeConverterCard`: Main card widget using `Card.filled` for Material 3 style
- Dropdown menus for unit selection
- TextField for input value
- Swap button between input/output
- Human-readable size indicator
- History view with ListView.builder
- Clear history confirmation dialog

## Usage Example

1. Enter a file size value in the input field
2. Select the input unit (e.g., MB)
3. Select the output unit (e.g., GB)
4. The converted value appears automatically
5. Tap swap button to reverse units
6. View human-readable size below the conversion
7. Tap history icon to view recent conversions
8. Tap history entry to reuse conversion

## Integration

### Provider Registration
Added to `Global.providerList` in `lib/data.dart`:
```dart
providerFileSizeConverter,
```

### MultiProvider Integration
Added to `MultiProvider` in `lib/main.dart`:
```dart
ChangeNotifierProvider.value(value: fileSizeConverterModel),
```

## Keywords
`filesize`, `size`, `bytes`, `kb`, `mb`, `gb`, `tb`, `pb`, `converter`, `file`, `storage`, `data`

## Tests

Tests are located in `test/widget_test.dart` under the `FileSizeConverter Provider tests` group:
- Unit conversion calculations
- Same unit conversion
- Large value conversions
- Model initialization
- Unit selection
- Value input handling
- Unit swapping
- History management
- Human-readable size formatting
- Widget rendering tests
- Provider registration tests

## Material 3 Compliance

- Uses `Card.filled` for primary content
- Uses `colorScheme.surfaceContainerHighest` for input/output field backgrounds
- Uses `colorScheme.outline` for borders
- Uses `IconButton.styleFrom()` for icon button styling
- Uses `DropdownButton` for unit selection
- Uses `AlertDialog` with `FilledButton` for confirmation