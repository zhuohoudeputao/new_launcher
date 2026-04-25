# Weather Provider Implementation

## Overview

The Weather provider displays current weather conditions with temperature, wind speed, location name, and a 3-day forecast.

## Provider Details

- **Provider Name**: Weather
- **Keywords**: weather, now
- **Widget Key**: Weather
- **Dependencies**: geolocator, http, SharedPreferences

## Features

### Current Weather Display

- Temperature (°C)
- Wind speed (km/h)
- Weather condition with icon
- Location name (city, country)
- Manual refresh button

### 3-Day Forecast

- Day name (Mon/Tue/Wed)
- Weather icon
- Max/min temperatures
- Horizontal scrollable display

### Caching

- 30-minute cache validity
- SharedPreferences storage
- Cache shown when offline
- "(cached)" indicator when data is stale

## Weather Codes

WMO weather codes mapping:
| Code | Condition |
|------|-----------|
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

## API

- **Forecast**: Open-Meteo API
- **Geocoding**: Open-Meteo Geocoding API (reverse lookup)
- **Default location**: NYC (40.71°N, -74.01°W)

## Model Classes

### WeatherCache

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
```

### ForecastDay

```dart
class ForecastDay {
  DateTime date;
  double maxTemp;
  double minTemp;
  int weathercode;
}
```

## Widget (WeatherCard)

- Card.filled style
- Icon + Temperature + Condition display
- Location name with cache indicator
- Wind speed display
- Forecast row with 3 future days
- Refresh button (with loading indicator)

## Testing

Tests verify:
- Provider existence in Global.providerList
- Keywords matching
- Weather icon mapping
- WeatherCard widget rendering

## Related Files

- `lib/providers/provider_weather.dart` - Provider implementation
- `docs/weather_service.md` - Detailed weather service documentation