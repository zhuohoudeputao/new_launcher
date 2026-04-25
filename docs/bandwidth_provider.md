# Bandwidth Calculator Provider

## Overview

The Bandwidth Calculator provider calculates network-related time, speed, and size values for practical network planning.

## Features

- **Three calculation modes**:
  - Time from Size & Speed: Calculate download/upload time given file size and bandwidth
  - Speed from Size & Time: Calculate required bandwidth given file size and time constraint
  - Size from Speed & Time: Calculate transferable data given bandwidth and time

- **File size units**: Bytes, KB, MB, GB, TB
- **Speed units**: bps, Kbps, Mbps, Gbps
- **Time formatting**: Automatic conversion to ms, seconds, minutes, hours, or days
- **Size formatting**: Automatic conversion to B, KB, MB, GB, TB
- **Calculation history**: Up to 10 entries stored
- **Clear history option**: With confirmation dialog

## Implementation Details

### File Location
- Provider: `lib/providers/provider_bandwidth.dart`

### Model Classes

#### `BandwidthCalculatorModel`
- Extends `ChangeNotifier`
- Manages calculation state and history
- Properties:
  - `mode`: Current calculation mode (CalculationMode enum)
  - `sizeUnit`: Current file size unit (BandwidthSizeUnit enum)
  - `speedUnit`: Current speed unit (BandwidthSpeedUnit enum)
  - `fileSize`: User-entered file size value
  - `speed`: User-entered speed value
  - `timeMinutes`: User-entered time value in minutes
  - `result`: Calculated result text
  - `history`: List of past calculations

#### Calculation Modes

##### Time from Size & Speed
Formula:
```
time = (fileSize * 8) / speed
```
Where:
- fileSize is converted to bytes using the selected size unit
- speed is converted to bits per second using the selected speed unit
- Result is formatted as ms, seconds, minutes, hours, or days

##### Speed from Size & Time
Formula:
```
speed = (fileSize * 8) / time
```
Where:
- fileSize is converted to bytes
- time is converted to seconds
- Result is formatted as Mbps or Kbps

##### Size from Speed & Time
Formula:
```
size = (speed * time) / 8
```
Where:
- speed is converted to bits per second
- time is converted to seconds
- Result is formatted as B, KB, MB, GB, or TB

### UI Components

#### `BandwidthCalculatorCard`
- Uses `Card.filled` for Material 3 style
- SegmentedButton for mode selection
- DropdownButtons for unit selection
- TextField for value input
- PrimaryContainer for result display
- History view with tap-to-reuse functionality

### Key Methods

- `init()`: Initialize model and perform initial calculation
- `setMode()`: Change calculation mode
- `setSizeUnit()`: Change file size unit
- `setSpeedUnit()`: Change speed unit
- `setFileSize()`: Update file size input
- `setSpeed()`: Update speed input
- `setTimeMinutes()`: Update time input
- `addToHistory()`: Save current calculation to history
- `clearHistory()`: Clear all history entries
- `useHistoryEntry()`: Load a history entry into inputs

## Unit Conversions

### Size Units (Binary)
- Bytes: 1
- KB: 1024 bytes
- MB: 1024 KB = 1,048,576 bytes
- GB: 1024 MB = 1,073,741,824 bytes
- TB: 1024 GB = 1,099,511,627,776 bytes

### Speed Units (Decimal)
- bps: 1 bit/s
- Kbps: 1,000 bits/s
- Mbps: 1,000,000 bits/s
- Gbps: 1,000,000,000 bits/s

## Tests

Tests are located in `test/widget_test.dart` under the `BandwidthCalculator Provider tests` group:
- Provider existence test
- Keywords validation
- Model initial state
- Mode switching
- Unit switching
- Calculation tests for all three modes
- Invalid input handling
- Zero speed handling
- History operations (add, clear, use)
- Max history limit test
- Refresh notification test
- Widget rendering tests
- Provider list inclusion test

## Keywords

`bandwidth download upload speed time calculate network transfer`

## Material 3 Compliance

- Uses `Card.filled` for container
- Uses `SegmentedButton` for mode selection
- Uses `IconButton.styleFrom()` for consistent styling
- Uses ColorScheme properties for colors
- Uses `DropdownButton` for unit selection
- Uses `TextField` with OutlineInputBorder
- Result section uses `primaryContainer` color