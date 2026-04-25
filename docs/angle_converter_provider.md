# Angle Converter Provider Implementation

## Overview

The Angle Converter provider converts between different angle measurement units.

## Provider Details

- **Provider Name**: AngleConverter
- **Keywords**: angle, convert, degree, radian, gradian, deg, rad, grad
- **Model**: angleConverterModel

## Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| deg | ° | Degree |
| rad | rad | Radian |
| grad | grad | Gradian |

## Conversion Formula

All conversions go through degrees as base unit:
- Radians: deg × (π/180) = rad, rad × (180/π) = deg
- Gradians: deg × (10/9) = grad, grad × (9/10) = deg

```dart
const degPerUnit = {
  'deg': 1.0,
  'rad': 180.0 / 3.1415926535897932,
  'grad': 0.9,
};
```

## Features

- Real-time conversion as values are typed
- Swap input/output units with one tap
- Same unit prevention (auto-selects different unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Model (AngleConverterModel)

```dart
class AngleConverterModel extends ChangeNotifier {
  String _inputUnit = 'deg';
  String _outputUnit = 'rad';
  static const int maxHistory = 10;
  
  static double convert(double value, String fromUnit, String toUnit);
}
```

## Widget (AngleConverterCard)

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

- `lib/providers/provider_angle.dart` - Provider implementation