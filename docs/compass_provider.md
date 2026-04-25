# Compass Provider Implementation

## Overview

The Compass provider provides a visual compass display with cardinal direction indicators and degree heading display. It allows manual adjustment of compass heading with rotation buttons and quick direction shortcuts.

## Implementation Details

### File Location
- Provider: `lib/providers/provider_compass.dart`

### Model: CompassModel

The CompassModel manages the compass state:
- `_heading`: Current compass heading in degrees (0-360)
- `_initialized`: Initialization state flag

#### Key Methods
- `init()`: Initialize the model
- `setHeading(double heading)`: Set compass heading with automatic wrapping (0-360 range)
- `adjustHeading(double delta)`: Adjust heading by a delta value
- `setToNorth()`: Set heading to 0° (North)
- `setToEast()`: Set heading to 90° (East)
- `setToSouth()`: Set heading to 180° (South)
- `setToWest()`: Set heading to 270° (West)
- `refresh()`: Trigger notifyListeners for UI update

#### Direction Properties
- `directionAbbreviation`: Returns cardinal abbreviation (N, NE, E, SE, S, SW, W, NW)
- `directionName`: Returns full direction name (North, North East, etc.)

### Card Widget: CompassCard

The CompassCard displays:
- Visual compass dial with custom painting
- Cardinal direction labels (N, E, S, W)
- Compass needle pointing to current heading
- Degree display (0-360°)
- Direction abbreviation and name
- Rotation buttons (+/-15°)
- Quick direction buttons (N, E, S, W)

### Custom Painter: CompassPainter

The CompassPainter draws:
- Outer circle with secondary color stroke
- Inner circle with subtle fill
- Tick marks around the dial (major marks every 90°)
- Cardinal direction labels (N, E, S, W)
- North needle (primary color)
- South needle (secondary color)
- Center dot with inner highlight

## Provider Registration

### In data.dart
```dart
import 'package:new_launcher/providers/provider_compass.dart';

// Add to providerList
providerCompass,
```

### In main.dart
```dart
import 'package:new_launcher/providers/provider_compass.dart';

// Add to MultiProvider
ChangeNotifierProvider.value(value: compassModel),
```

## Keywords

The Compass provider responds to keywords:
- compass, direction, north, south, east, west, heading, orientation, navigate

## Tests

Tests are located in `test/widget_test.dart`:
- Provider existence and keywords tests
- CompassModel initialization tests
- CompassModel heading manipulation tests (setHeading, adjustHeading)
- CompassModel heading wrapping tests (negative, >=360)
- CompassModel cardinal direction tests (N, NE, E, SE, S, SW, W, NW)
- CompassModel direction name tests
- CompassCard widget rendering tests
- CompassPainter existence tests

Total tests: 35 Compass-specific tests

## Material 3 Components Used
- `Card.filled` for container
- `CustomPaint` for compass dial
- `ActionChip` for quick direction buttons
- `IconButton` for rotation buttons
- `Icon(Icons.explore)` for compass icon

## Usage Example

```dart
// Setting heading to a specific direction
compassModel.setHeading(45.0);  // Set to 45° (NE)

// Adjusting heading
compassModel.adjustHeading(15.0);  // Add 15°
compassModel.adjustHeading(-15.0);  // Subtract 15°

// Quick direction shortcuts
compassModel.setToNorth();   // 0°
compassModel.setToEast();    // 90°
compassModel.setToSouth();   // 180°
compassModel.setToWest();    // 270°
```

## Visual Features

1. Compass Dial
   - Circular dial with tick marks
   - Major marks at cardinal directions
   - Minor marks every 10°

2. Compass Needle
   - North-pointing needle (primary color)
   - South-pointing needle (secondary color)
   - Center dot with inner highlight

3. Direction Display
   - Degree display with decimal precision
   - Cardinal abbreviation (N, E, S, W, etc.)
   - Full direction name (North, East, etc.)