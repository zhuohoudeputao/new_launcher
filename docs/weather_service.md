# Weather Service Documentation

## Overview

The weather service fetches current weather data based on the device's location and displays it as an info card in the launcher.

## API

- **Provider**: Open-Meteo API
- **Endpoint**: `https://api.open-meteo.com/v1/forecast`
- **Parameters**: latitude, longitude, current_weather=true

## Implementation Details

### Components

1. **Provider** (`lib/providers/provider_weather.dart`)
   - Name: `Weather`
   - Uses `geolocator` package for location
   - Uses `http` package for API calls

2. **Weather Data**
   - Temperature (Celsius)
   - Wind speed (km/h)
   - Weather condition (from WMO codes)

### Flow

1. Get device location using Geolocator
2. Request location permission if needed
3. Fall back to default location (NYC) if denied
4. Fetch weather from Open-Meteo API
5. Parse response and display on info card

### Weather Codes

| Code | Condition |
|------|---------|
| 0 | Clear sky |
| 1 | Mainly clear |
| 2 | Partly cloudy |
| 3 | Overcast |
| 45-48 | Fog |
| 51-55 | Drizzle |
| 61-65 | Rain |
| 71-75 | Snow |
| 80-82 | Rain showers |
| 85-86 | Snow showers |
| 95-99 | Thunderstorm |

### Permissions

- `ACCESS_FINE_LOCATION` - For precise GPS location
- `ACCESS_COARSE_LOCATION` - For network-based location
- `INTERNET` - For API calls

### Error Handling

- Network errors displayed as "Weather error" with message
- Location permission denied uses default coordinates
- Geolocation failures logged to console

## Usage

Users can trigger weather refresh by typing "weather now" in the command box.

## Future Improvements

- Add forecast data (hourly/daily)
- Support for multiple locations
- Weather cache to reduce API calls
- Manual location input option