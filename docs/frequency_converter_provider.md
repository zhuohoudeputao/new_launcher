# Frequency Converter Provider Implementation

## Overview

The Frequency Converter provider converts between different frequency/Hz units for electronics and audio applications.

## Provider Details

- **Provider Name**: FrequencyConverter
- **Keywords**: frequency, hz, khz, mhz, ghz, thz, convert, audio, radio, wave, signal
- **Model**: frequencyConverterModel

## Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| Hz | Hz | Hertz |
| kHz | kHz | Kilohertz |
| MHz | MHz | Megahertz |
| GHz | GHz | Gigahertz |
| THz | THz | Terahertz |

## Conversion Formula

All conversions use powers of 10:
- kHz = Hz × 1000
- MHz = kHz × 1000 = Hz × 1000000
- GHz = MHz × 1000
- THz = GHz × 1000

```dart
const hzPerUnit = {
  'Hz': 1.0,
  'kHz': 1000.0,
  'MHz': 1000000.0,
  'GHz': 1000000000.0,
  'THz': 1000000000000.0,
};
```

## Features

- Real-time conversion as values are typed
- Swap input/output units with one tap
- Same unit prevention (auto-selects different unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Model (FrequencyConverterModel)

```dart
class FrequencyConverterModel extends ChangeNotifier {
  String _inputUnit = 'MHz';
  String _outputUnit = 'kHz';
  static const int maxHistory = 10;
  
  static double convert(double value, String fromUnit, String toUnit);
}
```

## Widget (FrequencyConverterCard)

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

- `lib/providers/provider_frequency.dart` - Provider implementation