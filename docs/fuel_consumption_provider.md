# Fuel Consumption Provider Implementation

## Overview

The Fuel Consumption provider converts between different fuel efficiency/consumption units.

## Provider Details

- **Provider Name**: FuelConsumption
- **Keywords**: fuel, consumption, mpg, l100km, kmL, miles, gallon, liter, converter, efficiency
- **Model**: fuelConsumptionModel

## Supported Units

| Unit | Symbol | Description |
|------|--------|-------------|
| mpg_us | mpg (US) | Miles per US gallon |
| mpg_uk | mpg (UK) | Miles per UK gallon |
| l100km | L/100km | Liters per 100 kilometers |
| kmL | km/L | Kilometers per liter |
| miL | mi/L | Miles per liter |

## Conversion Formula

All conversions go through L/100km as base:
- mpg (US): (235.215 / mpg) L/100km
- mpg (UK): (282.481 / mpg) L/100km
- km/L: (100 / kmL) L/100km
- mi/L: (160.934 / miL) L/100km

Note: US gallon = 3.785 L, UK gallon = 4.546 L

## Features

- Real-time conversion as values are typed
- Swap input/output units with one tap
- Same unit prevention (auto-selects different unit)
- Conversion history (up to 10 entries)
- Tap history entries to reuse conversions
- Clear history with confirmation dialog

## Widget (FuelConsumptionCard)

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

- `lib/providers/provider_fuel.dart` - Provider implementation