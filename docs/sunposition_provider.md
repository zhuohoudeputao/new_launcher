# SunPosition Provider Implementation

## Overview

The SunPosition provider calculates and displays sun-related information for photographers, outdoor enthusiasts, and anyone interested in tracking sunlight throughout the day.

## Features

### Sun Times
- **Sunrise**: Exact time of sunrise for current location
- **Sunset**: Exact time of sunset for current location
- **Solar Noon**: Time when the sun is at its highest point
- **Day Length**: Duration between sunrise and sunset

### Photography Hours
- **Golden Hour (Morning)**: First hour after sunrise, ideal for warm-toned photos
- **Golden Hour (Evening)**: Last hour before sunset, ideal for warm-toned photos
- **Blue Hour (Morning)**: 40 minutes before sunrise, ideal for blue-toned photos
- **Blue Hour (Evening)**: 40 minutes after sunset, ideal for blue-toned photos

### Sun Position
- **Altitude**: Height of the sun above the horizon (degrees)
- **Azimuth**: Direction of the sun (degrees from North)
- **Compass Direction**: Cardinal direction (N, NE, E, SE, S, SW, W, NW)

### Phase Detection
- **Daytime**: Sun is above horizon
- **Nighttime**: Sun is below horizon
- **Golden Hour**: Currently in golden hour period
- **Blue Hour**: Currently in blue hour period

### Additional Features
- **Date Selection**: View sun positions for past/future dates
- **"Today" Button**: Quick reset to current date
- **Location-based**: Uses device location via geolocator

## Implementation Details

### Model (SunPositionModel)
- `init()`: Initialize and get location
- `refresh()`: Recalculate sun position
- `setDate(DateTime)`: Set a specific date for calculation
- `_getLocation()`: Get device coordinates via geolocator
- `_calculateSunPosition()`: Calculate all sun-related values
- `_calculateGoldenHours()`: Calculate golden hour times
- `_calculateBlueHours()`: Calculate blue hour times
- `_calculateCurrentSunPosition()`: Calculate current sun altitude/azimuth
- Helper methods for formatting and conversion

### Calculations
Uses astronomical algorithms:
- Solar declination calculation
- Equation of time correction
- Hour angle calculation
- Altitude and azimuth calculation

### Widget (SunPositionCard)
- Displays current phase with emoji indicator
- Shows sun times (sunrise, solar noon, sunset, day length)
- Shows photography hours (golden hour, blue hour)
- Shows sun position (altitude, azimuth with compass direction)
- Date selector with calendar picker

## Material 3 Components Used
- `Card.filled()` for main card
- `Card()` with `surfaceContainerHighest` for sub-cards
- `ActionChip` for "Today" button
- `showDatePicker` for date selection
- `IconButton.styleFrom()` for styled icons

## Keywords
sun, sunrise, sunset, golden, hour, solar, noon, day, length, altitude, azimuth, position

## Dependencies
- `geolocator`: For getting device location

## Test Coverage
- Model initialization tests
- Time formatting tests
- Altitude formatting tests
- Azimuth formatting and direction tests
- Day length calculations
- Phase detection tests
- Provider existence tests
- Widget rendering tests

## Usage Notes
- Location permission required for accurate calculations
- Default to "Location unavailable" if permission denied
- Works best with location services enabled
- Calculations use UTC for consistency