# Roman Numerals Provider

## Overview

The RomanNumerals provider implements a converter for Roman numerals, allowing users to convert numbers (1-3999) to Roman numerals and vice versa. This is an educational utility for understanding the ancient Roman numeral system.

## Features

- **Number to Roman conversion**: Convert integers from 1 to 3999 to their Roman numeral representation
- **Roman to Number conversion**: Convert valid Roman numerals back to integers
- **Dual conversion modes**: Toggle between number→Roman and Roman→number modes
- **Input validation**: Automatic validation with error messages for invalid inputs
- **Conversion history**: Store up to 10 recent conversions for quick reference
- **Swap functionality**: Quickly swap conversion direction with the current result

## Implementation Details

### Roman Numerals Conversion Rules

The converter follows standard Roman numeral rules:
- Basic symbols: I (1), V (5), X (10), L (50), C (100), D (500), M (1000)
- Subtraction rules: IV (4), IX (9), XL (40), XC (90), CD (400), CM (900)
- Maximum number supported: 3999 (MMMCMXCIX)

### Model (`RomanNumeralsModel`)

The model manages:
- Input value and conversion mode state
- Conversion output computation
- Error handling and validation
- History storage with timestamp

Key methods:
- `setInputValue(String)`: Update input and trigger conversion
- `setMode(ConversionMode)`: Switch between number→Roman and Roman→number
- `swapMode()`: Swap conversion direction, transferring output to input
- `addToHistory()`: Store current conversion in history
- `clearInput()`: Reset input field

### Validation Logic

Number to Roman validation:
- Must be a valid integer between 1 and 3999
- Invalid numbers show appropriate error messages

Roman to Number validation:
- Must contain only valid Roman symbols (I, V, X, L, C, D, M)
- Subtraction pairs must follow rules (I can subtract from V/X, X from L/C, C from D/M)
- Result is verified by converting back to ensure validity

### Widget (`RomanNumeralsCard`)

The widget uses Material 3 design:
- `Card.filled` for container styling
- `SegmentedButton` for mode selection
- `TextField` for input with validation
- Clear button for quick input reset
- History list with tap-to-apply functionality

## Usage Example

```dart
// Number to Roman
model.setInputValue('1994');
// Output: 'MCMXCIV'

// Roman to Number
model.setMode(ConversionMode.romanToNumber);
model.setInputValue('MMXVI');
// Output: '2016'

// Swap conversion direction
model.swapMode();
// Switches mode and transfers output to input
```

## Keywords

- roman
- numeral
- convert
- number
- latin
- I, V, X, L, C, D, M

## Testing Coverage

Tests cover:
- Model initialization
- Number to Roman conversion for various values
- Roman to Number conversion
- Invalid input handling
- Mode switching
- History management
- Widget rendering

Total tests for this provider: 29 tests