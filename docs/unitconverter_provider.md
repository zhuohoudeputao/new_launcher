# Unit Converter Provider

## Overview

The Unit Converter provider provides quick unit conversion functionality directly in the launcher. Users can convert between temperature, length, and weight units with a simple interface.

## Features

- **Three conversion categories**: Temperature, Length, and Weight
- **Real-time conversion**: Values are converted as you type
- **Unit swap**: Quickly swap input and output units
- **Conversion history**: Track recent conversions (up to 10 entries)
- **Material 3 design**: Uses `Card.filled` and `SegmentedButton`

## Supported Units

### Temperature
- Celsius (°C)
- Fahrenheit (°F)
- Kelvin (K)

### Length
- Meter (m)
- Kilometer (km)
- Centimeter (cm)
- Millimeter (mm)
- Inch (in)
- Foot (ft)
- Mile (mi)
- Yard (yd)

### Weight
- Kilogram (kg)
- Gram (g)
- Milligram (mg)
- Pound (lb)
- Ounce (oz)

## Implementation Details

### Model: `UnitConverterModel`

Located in `lib/providers/provider_unitconverter.dart`.

Key properties:
- `selectedCategory`: Current conversion category (temperature/length/weight)
- `inputUnit`: Source unit for conversion
- `outputUnit`: Target unit for conversion
- `inputValue`: User input value (string)
- `outputValue`: Converted result (string)
- `history`: List of conversion history entries (max 10)

Key methods:
- `setCategory(ConversionCategory)`: Switch between temperature/length/weight
- `setInputUnit(String)`: Change input unit
- `setOutputUnit(String)`: Change output unit
- `setInputValue(String)`: Update input value
- `swapUnits()`: Swap input and output units
- `convert(double, String, String)`: Static method for unit conversion
- `addToHistory()`: Save current conversion to history
- `clearHistory()`: Clear all history entries

### Widget: `UnitConverterCard`

The main UI widget that:
- Shows a `SegmentedButton` for category selection (Temp/Length/Weight)
- Displays dropdown selectors for units
- Provides input field for values
- Shows converted result
- Has swap button for quick unit reversal
- Shows history toggle button when history exists
- Has clear history button with confirmation dialog

## Search Keywords

The provider is searchable with keywords:
- `convert`, `unit`, `temperature`, `length`, `weight`, `mass`, `distance`
- Unit names: `cm`, `m`, `km`, `inch`, `foot`, `mile`, `celsius`, `fahrenheit`, `kelvin`, `kg`, `lb`, `gram`, `ounce`

## Material 3 Design

The widget uses Material 3 components:
- `Card.filled()` for the main container
- `SegmentedButton` for category selection
- `DropdownButton` for unit selection
- `TextField` with `OutlineInputBorder` for input
- `IconButton` for swap and history actions

## Conversion Formulas

### Temperature
- Celsius to Fahrenheit: `(C × 9/5) + 32`
- Celsius to Kelvin: `C + 273.15`
- Fahrenheit to Celsius: `(F - 32) × 5/9`

### Length
All conversions are based on meters:
- 1 meter = 1 m
- 1 kilometer = 1000 m
- 1 centimeter = 0.01 m
- 1 millimeter = 0.001 m
- 1 inch = 0.0254 m
- 1 foot = 0.3048 m
- 1 mile = 1609.344 m
- 1 yard = 0.9144 m

### Weight
All conversions are based on grams:
- 1 kilogram = 1000 g
- 1 gram = 1 g
- 1 milligram = 0.001 g
- 1 pound = 453.592 g
- 1 ounce = 28.3495 g

## Testing

Tests are located in `test/widget_test.dart` under the group `Unit Converter provider tests`.

Test coverage includes:
- Provider existence and keywords
- Model initialization and state management
- Unit conversions (temperature, length, weight)
- Category switching
- Unit swapping
- History management
- Widget rendering (loading state, initialized state)
- Edge cases (invalid input, negative values)

## Usage Example

```dart
final model = UnitConverterModel();
model.init();
model.setInputValue('100');
model.setInputUnit('celsius');
model.setOutputUnit('fahrenheit');
// outputValue will be '212'
```

## History Entry Structure

```dart
class ConversionHistory {
  final double inputValue;
  final String inputUnit;
  final double outputValue;
  final String outputUnit;
  final ConversionCategory category;
  final DateTime timestamp;
  
  String get inputSymbol => unitTypes[inputUnit]?.symbol ?? inputUnit;
  String get outputSymbol => unitTypes[outputUnit]?.symbol ?? outputUnit;
}
```