# Angle Converter Provider Implementation

## Overview

The Angle Converter provider provides angle unit conversion functionality for mathematics, engineering, physics, and graphics programming. It converts between degrees, radians, and gradians.

## Implementation Details

### Provider File: `lib/providers/provider_angle.dart`

### Model: `AngleConverterModel`

#### Properties
- `inputUnit`: Current input unit (default: 'deg')
- `outputUnit`: Current output unit (default: 'rad')
- `inputValue`: User input value as string
- `outputValue`: Converted result as string
- `isInitialized`: Boolean indicating initialization status
- `history`: List of conversion history entries (max 10)
- `hasHistory`: Boolean indicating if history has entries
- `availableUnits`: List of supported units

#### Supported Units
- `deg`: Degrees (°)
- `rad`: Radians (rad)
- `grad`: Gradians (grad)

#### Conversion Formulas
- Degrees to Radians: `rad = deg × (π / 180)`
- Radians to Degrees: `deg = rad × (180 / π)`
- Degrees to Gradians: `grad = deg × (10 / 9)`
- Gradians to Degrees: `deg = grad × (9 / 10)`
- Radians to Gradians: `grad = rad × (200 / π)`
- Gradians to Radians: `rad = grad × (π / 200)`

#### Methods
- `init()`: Initialize the model
- `refresh()`: Notify listeners
- `setInputUnit(unit)`: Set input unit, prevents same input/output
- `setOutputUnit(unit)`: Set output unit, prevents same input/output
- `setInputValue(value)`: Set input value and trigger conversion
- `swapUnits()`: Swap input and output units with values
- `clear()`: Clear input value to 0
- `addToHistory()`: Add current conversion to history
- `clearHistory()`: Clear all history entries
- `useHistoryEntry(entry)`: Apply a history entry to current state
- `convert(value, fromUnit, toUnit)`: Static conversion method

### Widget: `AngleConverterCard`

#### Features
- Material 3 `Card.filled` design
- Input/output unit dropdowns
- Input TextField with numeric keyboard
- Output display in styled container
- Swap units button with primary color
- History toggle view with history icon
- Clear history button with confirmation dialog
- Loading state indicator when uninitialized

### Integration

#### Provider Registration
Added to `Global.providerList` in `lib/data.dart`:
```dart
providerAngleConverter,
```

#### MultiProvider Registration
Added to `MultiProvider` in `lib/main.dart`:
```dart
ChangeNotifierProvider.value(value: angleConverterModel),
```

### Keywords
```
angle convert degree radian gradian deg rad grad
```

## Testing

### Test Coverage
- Provider existence in Global.providerList
- Keywords verification
- Model initialization
- ChangeNotifier implementation
- Default units verification
- Unit selection methods
- Value input handling
- Unit swap functionality
- Clear functionality
- Conversion accuracy tests (deg↔rad, deg↔grad, rad↔grad)
- Static convert method tests
- Invalid input handling
- Negative value handling
- Decimal value handling
- History operations (add, clear, max limit)
- Available units verification
- Refresh notification
- History entry reuse
- Widget rendering (loading state, initialized state)
- Widget components (input field, dropdowns)
- Same unit prevention
- Global provider list inclusion

### Test Count
36 tests added for AngleConverter provider.

## Use Cases

1. **Mathematics**: Convert between radians and degrees for trigonometric calculations
2. **Engineering**: Convert angles for CAD software and technical drawings
3. **Physics**: Convert angular measurements for physics calculations
4. **Graphics Programming**: Convert between degrees and radians for rotation matrices
5. **Navigation**: Convert angular measurements for bearing calculations

## History Feature

- Stores up to 10 conversion entries
- Each entry includes input value, input unit, output value, output unit, and timestamp
- Tap history entry to reuse previous conversion settings
- Clear all history with confirmation dialog