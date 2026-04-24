# Area Converter Provider Implementation

## Overview

The AreaConverter provider enables quick conversion between different area units, useful for real estate, construction, agriculture, and land measurement applications.

## Features

- Convert between 10 area units:
  - m² (square meter)
  - km² (square kilometer)
  - cm² (square centimeter)
  - mm² (square millimeter)
  - ha (hectare)
  - ac (acre)
  - ft² (square foot)
  - yd² (square yard)
  - in² (square inch)
  - mi² (square mile)
- Real-time conversion as values are entered
- Swap input/output units with one tap
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Implementation Details

### Model Class: AreaConverterModel

Located in `lib/providers/provider_area.dart`, implements:
- `ChangeNotifier` for reactive state management
- Area unit conversion logic using square meters as base unit
- History tracking with timestamps
- Input validation and error handling

### Conversion Logic

All conversions use square meters as the base unit:

```
Conversion factors to square meters:
- m²: 1.0
- km²: 1000000.0
- cm²: 0.0001
- mm²: 0.000001
- hectare: 10000.0
- acre: 4046.8564224
- ft²: 0.09290304
- yd²: 0.83612736
- in²: 0.00064516
- mi²: 2589988.110336
```

### UI Components

- `AreaConverterCard`: Material 3 Card.filled design
- Two DropdownButton widgets for unit selection
- TextField for input value
- IconButton for swap functionality
- History view with ListView.builder
- Confirmation dialog for clearing history

## Testing

Tests are located in `test/widget_test.dart` under 'AreaConverter Provider tests' group:

- Provider existence tests
- Model initialization tests
- Unit conversion accuracy tests (m² to acre, acre to m², m² to km², hectare to m², ft² to m², etc.)
- Swap functionality tests
- History operations tests
- Input validation tests
- Widget rendering tests
- Edge case handling tests (negative values, decimal values, invalid input)

Total tests: 43

## Usage

The AreaConverter appears as an info widget in the launcher's main list. Users can:

1. Select input and output units via dropdown menus
2. Enter area value in the input field
3. View converted result in the output field
4. Swap units using the swap button
5. Access history via the history button
6. Clear history via the clear button

## Keywords

Area, convert, square, meter, kilometer, centimeter, hectare, acre, foot, yard, inch, mile, sq, m2, km2