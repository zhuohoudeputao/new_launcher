# Number Base Converter Provider

## Overview

The Number Base Converter provider allows users to convert numbers between different base systems: Binary (base 2), Octal (base 8), Decimal (base 10), and Hexadecimal (base 16).

## Features

- **Real-time conversion**: Numbers are converted instantly as you type
- **Input sanitization**: Invalid digits are automatically filtered based on the selected base
- **Base swapping**: One-tap swap button to exchange input/output bases
- **Conversion history**: Track up to 10 recent conversions
- **History reuse**: Tap history entries to quickly apply previous conversions
- **Clear history**: Confirmation dialog to clear all history

## Implementation Details

### Number Bases Supported

| Base | Name | Suffix | Radix |
|------|------|--------|-------|
| Binary | Binary | BIN | 2 |
| Octal | Octal | OCT | 8 |
| Decimal | Decimal | DEC | 10 |
| Hexadecimal | Hexadecimal | HEX | 16 |

### Input Validation

The provider sanitizes input based on the selected base:
- Binary: Only allows digits 0-1
- Octal: Only allows digits 0-7
- Decimal: Only allows digits 0-9
- Hexadecimal: Allows digits 0-9 and letters A-F

### Conversion Logic

Conversions use Dart's built-in `int.parse()` and `toRadixString()` methods:
1. Parse input string with the input base's radix to get decimal value
2. Convert decimal value to output base's radix string

### UI Components

- `NumberBaseCard`: Main widget displaying the converter
- Dropdown selectors for input/output bases
- Text field for input with sanitization
- Output display container (non-editable, selectable)
- Swap button with arrow icon
- "Add to History" button (appears when input is valid)
- History list with tap-to-apply functionality

## Keywords

`convert, number, base, binary, octal, decimal, hex, hexadecimal, bin, oct, dec`

## Model Properties

- `inputValue`: Current input number string
- `inputBase`: Current input base ('binary', 'octal', 'decimal', 'hexadecimal')
- `outputBase`: Current output base
- `outputValue`: Calculated output (computed property)
- `history`: List of conversion history entries
- `isLoading`: Loading state indicator

## Model Methods

- `init()`: Initialize the model
- `setInputValue(value)`: Set and sanitize input
- `setInputBase(base)`: Change input base (sanitizes existing input)
- `setOutputBase(base)`: Change output base
- `swapBases()`: Exchange input/output bases with current output becoming new input
- `addToHistory()`: Save current conversion to history
- `applyFromHistory(entry)`: Apply a history entry to current state
- `clearHistory()`: Clear all history
- `refresh()`: Trigger UI update

## Constants

- `maxHistoryLength`: 10 (maximum history entries)

## Material 3 Components

- `Card.filled()` for main container
- `DropdownButton` for base selection
- `ElevatedButton` for "Add to History" action
- `SelectableText` for output display
- `AlertDialog` for clear confirmation
- `InkWell` for history items with tap feedback

## Testing

The provider includes comprehensive tests covering:
- Model initialization
- NumberBaseType values verification
- getAllBases() function
- setInputValue with sanitization
- Base-specific input validation
- Conversion accuracy (decimal to binary, hex, octal)
- Swap bases functionality
- History operations (add, limit, apply, clear)
- Widget rendering tests
- Provider registration verification

Total: 26 tests for this provider