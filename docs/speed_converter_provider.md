# Speed Converter Provider Implementation

## Overview

The Speed Converter provider converts between different speed/velocity units.

## Provider Details

- **Provider Name**: SpeedConverter
- **Keywords**: speed, convert, kmh, mph, ms, knots, velocity, fast
- **Model**: speedConverterModel

## Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| kmh | km/h | Kilometers per hour |
| mph | mph | Miles per hour |
| ms | m/s | Meters per second |
| fts | ft/s | Feet per second |
| knot | knot | Nautical miles per hour |

## Conversion Formula

All conversions go through meters per second as base unit:
```dart
const metersPerSecondPerUnit = {
  'kmh': 1000.0 / 3600.0,    // 0.2778
  'mph': 1609.344 / 3600.0,  // 0.4470
  'ms': 1.0,
  'fts': 0.3048,
  'knot': 1852.0 / 3600.0,   // 0.5144
};
```

## Features

- Real-time conversion as values are typed
- Swap input/output units with one tap
- Same unit prevention (auto-selects different unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Model (SpeedConverterModel)

```dart
class SpeedConverterModel extends ChangeNotifier {
  String _inputUnit = 'kmh';
  String _outputUnit = 'mph';
  String _inputValue = '0';
  String _outputValue = '0';
  final List<SpeedConversionHistory> _history = [];
  static const int maxHistory = 10;
  
  void setInputUnit(String unit);
  void setOutputUnit(String unit);
  void setInputValue(String value);
  void swapUnits();
  void clear();
  static double convert(double value, String fromUnit, String toUnit);
  void addToHistory();
  void clearHistory();
  void useHistoryEntry(SpeedConversionHistory entry);
}
```

## Widget (SpeedConverterCard)

- Card.filled style
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

- `lib/providers/provider_speed.dart` - Provider implementation