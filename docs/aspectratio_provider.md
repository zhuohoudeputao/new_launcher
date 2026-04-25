# AspectRatio Provider Implementation

## Overview

The AspectRatio provider calculates aspect ratios for image/video dimensions and helps users find matching dimensions based on preset ratios.

## Features

### Ratio Calculation
- Calculate simplified aspect ratio from width and height (e.g., 1920x1080 → 16:9)
- Display decimal ratio value (e.g., 1.778)
- Uses GCD (Greatest Common Divisor) for ratio simplification

### Preset Ratios
- 10 common aspect ratios:
  - 1:1 (square)
  - 4:3 (standard TV)
  - 3:2 (classic photo)
  - 16:9 (HD video)
  - 16:10 (widescreen monitor)
  - 21:9 (ultrawide)
  - 2:3 (portrait photo)
  - 3:4 (portrait standard)
  - 9:16 (vertical HD)
  - 10:16 (vertical widescreen)

### Target Dimension Calculator
- Enter target width to calculate matching height
- Enter target height to calculate matching width
- Based on selected preset ratio

### History
- Track up to 10 previous calculations
- Load previous calculations from history
- Clear history with confirmation dialog
- Timestamp display (just now, Xm ago, Xh ago, Xd ago)

## Implementation Details

### Model (AspectRatioModel)
- `setWidth(int value)` - Set width dimension
- `setHeight(int value)` - Set height dimension
- `setTargetWidth(int value)` - Set target width and calculate height
- `setTargetHeight(int value)` - Set target height and calculate width
- `setSelectedPreset(int index)` - Select a preset ratio
- `gcd(int a, int b)` - Calculate greatest common divisor
- `calculateRatio(int w, int h)` - Calculate simplified ratio string
- `calculateDecimalRatio(int w, int h)` - Calculate decimal ratio value
- `addToHistory(int w, int h)` - Add calculation to history
- `loadFromHistory(entry)` - Load from history entry
- `clearHistory()` - Clear all history
- `toggleHistory()` - Toggle history visibility
- `clearInputs()` - Reset inputs to defaults

### Widget (AspectRatioCalculatorCard)
- StatefulWidget with TextEditingController for inputs
- Material 3 Card.filled styling
- ActionChip for preset ratio selection
- Card.outlined for result display
- TextField for dimension inputs
- History section with ListTile for entries

## State Management

- Uses SharedPreferences for history persistence
- ChangeNotifier pattern for UI updates
- Global model instance: `aspectRatioModel`

## Keywords

- aspectratio, aspect, ratio, dimensions, width, height, calculate, calculator, image, video, resize, screen, resolution

## Usage

The provider is automatically added to the info widget list on app startup. Users can:
1. Enter width and height to see the simplified ratio
2. Select a preset ratio to use for target calculations
3. Enter a target dimension to get the matching other dimension
4. View history of previous calculations
5. Load previous calculations from history

## Files Modified

- `lib/providers/provider_aspectratio.dart` - New provider implementation
- `lib/data.dart` - Added import and provider to Global.providerList
- `lib/main.dart` - Added import and model to MultiProvider
- `test/widget_test.dart` - Added 28 tests for the provider
- `AGENTS.md` - Updated documentation

## Tests Added

- Provider existence and keywords tests
- Model initialization tests
- Set/get operations tests
- GCD calculation tests
- Ratio calculation tests
- Decimal ratio calculation tests
- History operations tests
- Widget rendering tests
- Provider list inclusion tests