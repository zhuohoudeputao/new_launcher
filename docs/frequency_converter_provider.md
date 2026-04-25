# Frequency Converter Provider

## Overview

The FrequencyConverter provider is a utility for converting between frequency units (Hz, kHz, MHz, GHz, THz). It is useful for electronics, audio, radio, and signal processing applications.

## Implementation

### Provider Structure

- **File**: `lib/providers/provider_frequency.dart`
- **Model**: `FrequencyConverterModel`
- **Widget**: `FrequencyConverterCard`
- **Provider**: `providerFrequencyConverter`

### Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| Hertz | Hz | Base unit of frequency |
| Kilohertz | kHz | 1,000 Hz |
| Megahertz | MHz | 1,000,000 Hz |
| Gigahertz | GHz | 1,000,000,000 Hz |
| Terahertz | THz | 1,000,000,000,000 Hz |

### Conversion Logic

Conversions use the SI prefix system:
- Each unit is a multiple of Hz by powers of 1000
- `convert(value, fromUnit, toUnit)` handles all conversions

```dart
const hertzPerUnit = {
  'Hz': 1.0,
  'kHz': 1000.0,
  'MHz': 1000000.0,
  'GHz': 1000000000.0,
  'THz': 1000000000000.0,
};
```

### Model Features

- **Input/Output Units**: Configurable dropdowns for unit selection
- **Real-time Conversion**: Converts as user types
- **Unit Swapping**: Swap input/output units with one tap
- **History Tracking**: Up to 10 conversion history entries
- **Same Unit Prevention**: Automatically prevents input and output units being the same

### UI Components

- **Card.filled**: Material 3 styled card
- **DropdownButton**: Unit selection dropdowns
- **TextField**: Numeric input field
- **IconButton**: Swap units and history controls
- **History View**: List of previous conversions

### Keywords

`frequency hz khz mhz ghz thz convert audio radio wave signal`

### Integration

The provider is registered in:
- `lib/data.dart`: Added to `Global.providerList`
- `lib/main.dart`: Added to `MultiProvider` as `frequencyConverterModel`

## Testing

Tests are located in `test/widget_test.dart` under the `FrequencyConverter Provider tests` group:

- Provider existence and configuration
- Model initialization and state management
- Unit conversion accuracy (MHz→kHz, GHz→MHz, kHz→Hz, THz→GHz, Hz→kHz)
- Static conversion method verification
- History operations (add, clear, use entry, max limit)
- UI widget rendering (loading state, initialized state, input field)
- Same unit prevention logic

## Usage Examples

- Audio: Convert 44.1 kHz to Hz (44,100 Hz)
- CPU Speed: Convert 3.5 GHz to MHz (3,500 MHz)
- Radio: Convert 100 MHz to kHz (100,000 kHz)
- Network: Convert 5 GHz (WiFi frequency) to MHz (5,000 MHz)