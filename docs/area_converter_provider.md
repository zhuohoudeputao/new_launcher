# Area Converter Provider Implementation

## Overview

The Area Converter provider converts between different area/surface measurement units.

## Provider Details

- **Provider Name**: AreaConverter
- **Keywords**: area, convert, square, meter, kilometer, centimeter, hectare, acre, foot, yard, inch, mile, sq, m2, km2
- **Model**: areaConverterModel

## Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| m² | m² | Square Meter |
| km² | km² | Square Kilometer |
| cm² | cm² | Square Centimeter |
| mm² | mm² | Square Millimeter |
| ha | ha | Hectare |
| ac | ac | Acre |
| ft² | ft² | Square Foot |
| yd² | yd² | Square Yard |
| in² | in² | Square Inch |
| mi² | mi² | Square Mile |

## Conversion Formula

All conversions go through square meters:
- km² = m² × 0.000001 = m² / 1000000
- cm² = m² × 10000
- mm² = m² × 1000000
- ha = m² × 0.0001 = 10000 m²
- ac = m² × 0.000247105 (approximately 4047 m²)
- ft² = m² × 10.7639 (approximately 0.0929 m²)
- yd² = m² × 1.19599 (approximately 0.836 m²)
- in² = m² × 1550.003
- mi² = m² × 0.000000386102

## Features

- Real-time conversion as values are typed
- Swap input/output units with one tap
- Same unit prevention (auto-selects different unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Widget (AreaConverterCard)

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

- `lib/providers/provider_area.dart` - Provider implementation