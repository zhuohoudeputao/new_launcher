# Speed Converter Provider Implementation

## Overview

The SpeedConverter provider enables quick conversion between different speed units, useful for travel, automotive, aviation, and sports applications.

## Features

- Convert between 5 speed units:
  - km/h (kilometers per hour)
  - mph (miles per hour)
  - m/s (meters per second)
  - ft/s (feet per second)
  - knot (nautical miles per hour)
- Real-time conversion as values are entered
- Swap input/output units with one tap
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Implementation Details

### Model Class: SpeedConverterModel

Located in `lib/providers/provider_speed.dart`, implements:
- `ChangeNotifier` for reactive state management
- Speed unit conversion logic using meters per second as base unit
- History tracking with timestamps
- Input validation and error handling

### Conversion Logic

All conversions use meters per second (m/s) as the base unit:

```
Conversion factors to m/s:
- km/h: 1000/3600 = 0.277778
- mph: 1609.344/3600 = 0.44704
- m/s: 1.0
- ft/s: 0.3048
- knot: 1852/3600 = 0.514444
```

### UI Components

- `SpeedConverterCard`: Material 3 Card.filled design
- Two DropdownButton widgets for unit selection
- TextField for input value
- IconButton for swap functionality
- History view with ListView.builder
- Confirmation dialog for clearing history

## Testing

Tests are located in `test/widget_test.dart` under 'SpeedConverter Provider tests' group:

- Provider existence tests
- Model initialization tests
- Unit conversion accuracy tests
- Swap functionality tests
- History operations tests
- Input validation tests
- Widget rendering tests
- Edge case handling tests

Total tests: 36

## Usage

The SpeedConverter appears as an info widget in the launcher's main list. Users can:

1. Select input and output units via dropdown menus
2. Enter speed value in the input field
3. View converted result in the output field
4. Swap units using the swap button
5. Access history via the history button
6. Clear history via the clear button

## Keywords

Speed, convert, kmh, mph, ms, knots, velocity, fast