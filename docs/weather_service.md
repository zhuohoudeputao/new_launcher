# Weather Service Documentation

## Overview

The weather service fetches current weather data based on the device's location and displays it as an info card in the launcher. It now includes location name display, multi-day forecast, and manual refresh capability.

## API

- **Provider**: Open-Meteo API
- **Endpoint**: `https://api.open-meteo.com/v1/forecast`
- **Parameters**: latitude, longitude, current_weather=true, daily=temperature_2m_max,temperature_2m_min,weathercode, timezone=auto

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
   - Location name (city, country)
   - 3-day forecast (max/min temps, weather codes)

### Flow

1. Get device location using Geolocator
2. Request location permission if needed
3. Fall back to default location (NYC) if denied
4. Fetch weather from Open-Meteo API (current + daily forecast)
5. Get location name from geocoding API
6. Parse response and display on weather card
7. Save to cache for offline usage

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
- Cached data displayed when API unavailable

## Usage

Users can trigger weather refresh by:
1. Typing "weather now" in the command box
2. Tapping the refresh button on the weather card

## Weather Card Features

### Current Weather Display
- Current temperature with weather icon
- Weather condition text
- Location name (city, country)
- Wind speed
- Refresh button

### 3-Day Forecast
- Day name (Mon/Tue/Wed/etc)
- Weather icon for each day
- Max and min temperatures

### Cache Indicator
- Shows "(cached)" when data is older than 5 minutes
- Gray text indicates cached data

## Caching (Implemented)

Weather data is cached for 30 minutes to support offline usage and reduce API calls.

### Cache Implementation

- **Storage**: SharedPreferences
- **Key**: `Weather.Cache`
- **Validity**: 30 minutes (`_cacheValidity`)
- **Class**: `WeatherCache`

### Cache Behavior

| Scenario | Behavior |
|----------|----------|
| API success | Save new cache with location and forecast, display fresh data |
| Network error | Show cached data with location and forecast |
| Geolocation error | Show cached data if available |
| Cache expired (30+ min) | Fetch fresh data, ignore old cache |
| No cache available | Show error message |

### WeatherCache Fields

```dart
class WeatherCache {
  double temperature;
  double windspeed;
  int weathercode;
  double latitude;
  double longitude;
  String locationName;
  List<ForecastDay> forecast;
  DateTime timestamp;
}

class ForecastDay {
  DateTime date;
  double maxTemp;
  double minTemp;
  int weathercode;
}
```

## Geocoding API

- **Provider**: Open-Meteo Geocoding
- **Endpoint**: `https://geocoding-api.open-meteo.com/v1/reverse`
- **Parameters**: latitude, longitude, count=1
- **Returns**: City name, country name
- **Fallback**: Coordinates string if geocoding fails

## Future Improvements

- Support for multiple locations
- Manual location input option
- Hourly forecast display
- Weather alerts integration