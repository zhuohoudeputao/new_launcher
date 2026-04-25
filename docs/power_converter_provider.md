# Power Converter Provider Implementation

## Overview

The Power Converter provider converts between different power units for engineering and physics applications.

## Provider Details

- **Provider Name**: PowerConverter
- **Keywords**: power, convert, watt, kilowatt, horsepower, hp, mw, btu, energy, wattage
- **Model**: powerConverterModel

## Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| W | W | Watt |
| kW | kW | Kilowatt |
| MW | MW | Megawatt |
| hp | hp | Horsepower |
| BTU/hr | BTU/hr | British Thermal Unit per hour |

## Conversion Formula

All conversions go through Watts:
- kW = W × 1000
- MW = kW × 1000 = W × 1000000
- hp = W × 0.00134102 (approximately 746 W)
- BTU/hr = W × 3.41214

## Features

- Real-time conversion as values are typed
- Swap input/output units with one tap
- Same unit prevention (auto-selects different unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Widget (PowerConverterCard)

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

- `lib/providers/provider_power.dart` - Provider implementation