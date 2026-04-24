# Volume Converter Provider Implementation

## Overview

The VolumeConverter provider enables quick conversion between different volume units, useful for cooking, chemistry, automotive, and industrial applications.

## Features

- Convert between 10 volume units:
  - L (liter)
  - mL (milliliter)
  - gal (US gallon)
  - qt (US quart)
  - pt (US pint)
  - cup (US cup)
  - fl oz (US fluid ounce)
  - m³ (cubic meter)
  - cm³ (cubic centimeter / cc)
  - in³ (cubic inch)
- Real-time conversion as values are entered
- Swap input/output units with one tap
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Implementation Details

### Model Class: VolumeConverterModel

Located in `lib/providers/provider_volume.dart`, implements:
- `ChangeNotifier` for reactive state management
- Volume unit conversion logic using liters as base unit
- History tracking with timestamps
- Input validation and error handling

### Conversion Logic

All conversions use liters as the base unit:

```
Conversion factors to liters:
- liter: 1.0
- milliliter: 0.001
- gallon (US): 3.785411784
- quart (US): 0.946352946
- pint (US): 0.473176473
- cup (US): 0.2365882365
- fl oz (US): 0.0295735295625
- m³: 1000.0
- cm³: 0.001
- in³: 0.016387064
```

### UI Components

- `VolumeConverterCard`: Material 3 Card.filled design
- Two DropdownButton widgets for unit selection
- TextField for input value
- IconButton for swap functionality
- History view with ListView.builder
- Confirmation dialog for clearing history

## Testing

Tests are located in `test/widget_test.dart` under 'VolumeConverter Provider tests' group:

- Provider existence tests
- Model initialization tests
- Unit conversion accuracy tests (liter to gallon, gallon to liter, liter to milliliter, etc.)
- Swap functionality tests
- History operations tests
- Input validation tests
- Widget rendering tests
- Edge case handling tests (negative values, decimal values, invalid input)

Total tests: 36

## Usage

The VolumeConverter appears as an info widget in the launcher's main list. Users can:

1. Select input and output units via dropdown menus
2. Enter volume value in the input field
3. View converted result in the output field
4. Swap units using the swap button
5. Access history via the history button
6. Clear history via the clear button

## Keywords

Volume, convert, liter, gallon, ml, milliliter, quart, pint, cup, fluid ounce, cubic meter, cm3, in3, cc