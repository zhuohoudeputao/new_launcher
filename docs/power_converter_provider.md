# Power Converter Provider Implementation

## Overview

Added a new PowerConverter provider for converting between power units (Watts, Kilowatts, Megawatts, Horsepower, BTU/hr). Useful for engineering, physics, and electrical applications.

## Implementation Details

### File: `lib/providers/provider_power.dart`

### Power Units Supported
- Watt (W) - base unit
- Kilowatt (kW) = 1000 W
- Megawatt (MW) = 1,000,000 W
- Horsepower (hp) ≈ 745.7 W (mechanical horsepower)
- BTU/hr ≈ 0.293071 W

### Model: `PowerConverterModel`
- Extends ChangeNotifier for state management
- Real-time conversion as values are entered
- Swap input/output units with one tap
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

### UI: `PowerConverterCard`
- Uses `Card.filled` for Material 3 style
- DropdownButtonFormField for unit selection
- TextField for input (numeric with decimal)
- IconButton for swap functionality
- ListTile for history display

## Integration

### data.dart Changes
- Added import for `provider_power.dart`
- Added `providerPowerConverter` to `Global.providerList`

### main.dart Changes
- Added import for `provider_power.dart`
- Added `powerConverterModel` to MultiProvider

## Features

1. **Real-time Conversion**: Converts as user types
2. **Unit Swapping**: One-tap swap of input/output units
3. **Same Unit Prevention**: Automatically selects different unit when input equals output
4. **History Tracking**: Saves up to 10 recent conversions
5. **History Reuse**: Tap history entry to restore conversion
6. **Clear Options**: Clear input and clear all history

## Keywords
`power convert watt kilowatt horsepower hp mw btu energy wattage`

## Tests Added (39 tests)

### Provider Tests
- Provider existence in Global.providerList
- Keywords validation
- Model initialization
- Default units
- setInputUnit/setOutputUnit operations
- setInputValue operations
- swapUnits functionality
- clear operations
- Conversion accuracy (W→kW, kW→W, hp→W, W→hp, MW→kW, kW→MW)
- Invalid input handling
- Negative values
- Decimal values
- Zero handling
- availableUnits validation
- History operations (add, clear, limit, reuse)
- Same unit prevention
- notifyListeners calls

### Widget Tests
- Loading state rendering
- Initialized state rendering
- Input field presence
- Widget existence

## Total tests: 2389 tests (39 new PowerConverter tests)