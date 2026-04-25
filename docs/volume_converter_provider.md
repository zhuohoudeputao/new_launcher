# Volume Converter Provider Implementation

## Overview

The Volume Converter provider converts between different volume/capacity units.

## Provider Details

- **Provider Name**: VolumeConverter
- **Keywords**: volume, convert, liter, gallon, ml, milliliter, quart, pint, cup, fluid ounce, cubic meter, cm3, in3, cc
- **Model**: volumeConverterModel

## Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| liter | L | Liter |
| milliliter | mL | Milliliter |
| gallon | gal | US Gallon |
| quart | qt | US Quart |
| pint | pt | US Pint |
| cup | cup | US Cup |
| floz | fl oz | US Fluid Ounce |
| m3 | m³ | Cubic Meter |
| cm3 | cm³ | Cubic Centimeter |
| in3 | in³ | Cubic Inch |

## Conversion Formula

All conversions go through liters as base unit:
```dart
const litersPerUnit = {
  'liter': 1.0,
  'milliliter': 0.001,
  'gallon': 3.785411784,
  'quart': 0.946352946,
  'pint': 0.473176473,
  'cup': 0.2365882365,
  'floz': 0.0295735295625,
  'm3': 1000.0,
  'cm3': 0.001,
  'in3': 0.016387064,
};
```

## Features

- Real-time conversion as values are typed
- Swap input/output units with one tap
- Same unit prevention (auto-selects different unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Model (VolumeConverterModel)

```dart
class VolumeConverterModel extends ChangeNotifier {
  String _inputUnit = 'liter';
  String _outputUnit = 'gallon';
  String _inputValue = '0';
  String _outputValue = '0';
  final List<VolumeConversionHistory> _history = [];
  static const int maxHistory = 10;
  
  void setInputUnit(String unit);
  void setOutputUnit(String unit);
  void setInputValue(String value);
  void swapUnits();
  void clear();
  static double convert(double value, String fromUnit, String toUnit);
  void addToHistory();
  void clearHistory();
  void useHistoryEntry(VolumeConversionHistory entry);
}
```

## Widget (VolumeConverterCard)

- Card.filled style
- Icon: water_drop
- DropdownButton for unit selection
- TextField for input value
- Swap button between input/output
- History toggle view

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Model initialization and state
- Conversion accuracy
- History operations
- Widget rendering

## Related Files

- `lib/providers/provider_volume.dart` - Provider implementation