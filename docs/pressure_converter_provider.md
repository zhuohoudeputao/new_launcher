# Pressure Converter Provider

## Overview

The PressureConverter provider is a unit converter for pressure measurements commonly used in engineering and physics. It supports conversion between 8 pressure units with real-time calculations and history tracking.

## Implementation

### File Location
`lib/providers/provider_pressure.dart`

### Provider Structure
```dart
MyProvider providerPressureConverter = MyProvider(
    name: "PressureConverter",
    provideActions: _provideActions,
    initActions: _initActions,
    update: _update);
```

### Model
- `PressureConverterModel` - Manages conversion state, units, input/output values, and history

## Supported Units

| Unit | Symbol | To Pascal Factor |
|------|--------|------------------|
| Pascal | Pa | 1.0 |
| Kilopascal | kPa | 1000.0 |
| Megapascal | MPa | 1000000.0 |
| Bar | bar | 100000.0 |
| Millibar | mbar | 100.0 |
| PSI | psi | 6894.76 |
| Atmosphere | atm | 101325.0 |
| Torr | Torr | 133.322 |

## Features

### Real-time Conversion
- Converts input values as they are typed
- Handles decimal values, negative values, and zero
- Displays appropriate precision based on result magnitude

### Unit Swapping
- Swap button to quickly exchange input and output units
- Same unit prevention - automatically selects different output unit when input unit equals output

### History
- Stores up to 10 conversion entries
- Tap history entry to reuse previous conversion units
- Clear history with confirmation dialog
- Timestamp display (just now, Xm ago, Xh ago, Xd ago)

### UI Components
- Uses Material 3 `Card.filled` for container
- `DropdownButtonFormField<PressureUnit>` for unit selection
- `TextField` for input value
- `IconButton` for swap button
- `ElevatedButton` for save action
- `TextButton` for clear and clear history actions

## Keywords
`pressure, convert, pascal, bar, psi, atmosphere, atm, kpa, mpa, torr`

## Integration

### main.dart
Added to MultiProvider:
```dart
ChangeNotifierProvider.value(value: pressureConverterModel),
```

### data.dart
Added to providerList:
```dart
providerPressureConverter,
```

## Tests
Located in `test/widget_test.dart` under 'PressureConverter Provider tests' group:
- Provider existence and keywords
- Model initialization and state
- Unit selection and conversion
- History operations
- Widget rendering
- Input validation (invalid, negative, decimal, zero)
- Same unit prevention

## Usage Example
1. Open launcher app
2. Find "Pressure Converter" card
3. Enter pressure value in input field
4. Select input unit (e.g., "bar")
5. Select output unit (e.g., "psi")
6. Result is displayed automatically
7. Tap "Save" to add to history
8. Tap history entry to reuse conversion