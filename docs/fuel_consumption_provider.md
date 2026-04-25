# Fuel Consumption Converter Provider Implementation

## Overview

The FuelConsumption provider implements a fuel efficiency/consumption converter for vehicles, allowing conversion between mpg (US), mpg (UK), L/100km, km/L, and mi/L units.

## Implementation Details

### Provider Structure

Located in `lib/providers/provider_fuel.dart`:

- **Model**: `FuelConsumptionModel` - ChangeNotifier-based state management
- **History**: `FuelConsumptionHistoryEntry` - Tracks conversion history
- **Widget**: `FuelConsumptionCard` - Material 3 styled UI card
- **Provider**: `providerFuel` - MyProvider instance for the provider system

### Supported Units

Five fuel consumption units are supported:

1. **mpg** - Miles per Gallon (US) - US standard fuel efficiency
2. **mpguk** - Miles per Gallon (UK) - UK imperial gallon standard
3. **L/100km** - Liters per 100 km - European standard consumption
4. **km/L** - Kilometers per Liter - Asian/alternative efficiency measure
5. **mi/L** - Miles per Liter - Alternative efficiency measure

### Conversion Logic

All conversions use L/100km as the intermediate unit:

```
mpg (US) → L/100km: 235.214583 / mpg
mpg (UK) → L/100km: 282.481 / mpg
L/100km → mpg (US): 235.214583 / L/100km
L/100km → mpg (UK): 282.481 / L/100km
km/L → L/100km: 100 / km/L
L/100km → km/L: 100 / L/100km
mi/L → L/100km: 160.9344 / mi/L
L/100km → mi/L: 160.9344 / L/100km
```

### Features

- Real-time conversion as values are entered
- Swap input/output units with one tap
- Same unit prevention (automatically swaps when selecting same unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog
- Input validation (handles empty, zero, negative values)

### State Management

- Uses SharedPreferences for history persistence
- ChangeNotifier pattern for reactive updates
- Provider integration with Consumer widget

### UI Components

- Card.filled for Material 3 styling
- DropdownButton for unit selection
- TextField for numeric input
- IconButton for swap action
- ListView.builder for history display
- ElevatedButton for actions

## Integration

### data.dart

- Import: `import 'package:new_launcher/providers/provider_fuel.dart';`
- Provider list: Added `providerFuel` to `Global.providerList`

### main.dart

- Import: `import 'package:new_launcher/providers/provider_fuel.dart';`
- MultiProvider: Added `ChangeNotifierProvider.value(value: fuelConsumptionModel)`

### Keywords

The provider responds to these search keywords:
- fuel, consumption, mpg, l100km, kmL, miles, gallon, liter, converter, efficiency

## Testing

Located in `test/widget_test.dart` under 'FuelConsumption Provider tests' group:

- Provider existence and keywords tests
- Model initialization and state tests
- Conversion accuracy tests (mpg, L/100km, km/L, mi/L)
- History management tests (add, use, clear, max limit)
- UI rendering tests
- Edge case handling (empty, zero, negative)

## Usage Example

```dart
// Conversion: 25 mpg (US) to L/100km
fuelConsumptionModel.setInputUnit('mpg');
fuelConsumptionModel.setOutputUnit('L/100km');
fuelConsumptionModel.setInputValue('25');
// Output: ~9.4086 L/100km

// Conversion: 10 L/100km to km/L
fuelConsumptionModel.setInputUnit('L/100km');
fuelConsumptionModel.setOutputUnit('km/L');
fuelConsumptionModel.setInputValue('10');
// Output: ~10 km/L
```

## Common Conversions

- 25 mpg (US) ≈ 9.4 L/100km
- 35 mpg (US) ≈ 6.7 L/100km
- 8 L/100km ≈ 29.4 mpg (US)
- 15 km/L ≈ 35.3 mpg (US)