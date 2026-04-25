# Pressure Converter Provider Implementation

## Overview

The Pressure Converter provider converts between different pressure units for engineering and physics applications.

## Provider Details

- **Provider Name**: PressureConverter
- **Keywords**: pressure, convert, pascal, bar, psi, atmosphere, atm, kpa, mpa, torr
- **Model**: pressureConverterModel

## Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| Pa | Pa | Pascal |
| kPa | kPa | Kilopascal |
| MPa | MPa | Megapascal |
| bar | bar | Bar |
| mbar | mbar | Millibar |
| psi | psi | Pound per square inch |
| atm | atm | Standard atmosphere |
| Torr | Torr | Torr |

## Conversion Formula

All conversions go through Pascals:
- kPa = Pa × 1000
- MPa = kPa × 1000 = Pa × 1000000
- bar = Pa × 0.00001 = 100000 Pa
- mbar = bar × 1000 = Pa × 0.01
- psi = Pa × 0.000145038 (approximately 6895 Pa)
- atm = Pa × 0.00000986923 (approximately 101325 Pa)
- Torr = Pa × 0.00750062

## Features

- Real-time conversion as values are typed
- Swap input/output units with one tap
- Same unit prevention (auto-selects different unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Widget (PressureConverterCard)

- Card.filled style
- DropdownButtonFormField for unit selection
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

- `lib/providers/provider_pressure.dart` - Provider implementation