# Coordinates Converter Provider Implementation

## Overview

The Coordinates Converter provider allows conversion between geographical coordinate formats. It converts between Decimal Degrees (DD) and Degrees Minutes Seconds (DMS) formats for latitude and longitude coordinates.

## Implementation Details

### Provider File
- **Location**: `lib/providers/provider_coordinates.dart`
- **Provider Name**: `providerCoordinatesConverter`
- **Model**: `CoordinatesConverterModel`

### Features

1. **Decimal Degrees (DD) Format**: Input coordinates as decimal values (e.g., 40.7128, -74.0060)
2. **DMS Output**: Automatic conversion to Degrees Minutes Seconds format (e.g., 40° 42' 45" N, 74° 0' 21" W)
3. **Coordinate Limits**: Latitude clamped to -90 to 90, Longitude clamped to -180 to 180
4. **Direction Indicators**: N/S for latitude, E/W for longitude
5. **Swap Coordinates**: One-tap swap of latitude and longitude values
6. **History Tracking**: Save coordinates to history (up to 10 entries)
7. **Load from History**: Tap history entries to reload previous coordinates

### Conversion Logic

#### DD to DMS Conversion
- Extract degrees from decimal: `degrees = floor(abs(decimal))`
- Extract minutes: `minutes = floor((abs(decimal) - degrees) * 60)`
- Extract seconds: `seconds = round((minutesDecimal - minutes) * 60)`
- Direction: N for positive latitude, S for negative, E for positive longitude, W for negative

#### DMS to DD Conversion
- Formula: `decimal = degrees + minutes/60 + seconds/3600`
- Apply negative sign for S or W directions

### Default Values
- Latitude: 40.7128 (New York City)
- Longitude: -74.0060

### UI Components
- **Card.filled**: Material 3 style card container
- **TextField**: Input fields for latitude and longitude
- **IconButton**: Swap coordinates, save to history, clear history
- **ListView.builder**: History view with selectable entries

### Keywords
`coordinates, convert, decimal, dms, degree, latitude, longitude, gps, location`

## Model Structure

```dart
class CoordinatesConverterModel extends ChangeNotifier {
  double _latitude = 40.7128;
  double _longitude = -74.0060;
  bool _isInitialized = false;
  final List<CoordinatesConversionHistory> _history = [];
  static const int maxHistory = 10;

  // Getters
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get dmsLatitude => _convertToDMS(_latitude, true);
  String get dmsLongitude => _convertToDMS(_longitude, false);
  bool get isInitialized => _isInitialized;
  List<CoordinatesConversionHistory> get history;
  bool get hasHistory;

  // Methods
  void init();
  void refresh();
  void setLatitude(double value);
  void setLongitude(double value);
  void setLatitudeFromString(String value);
  void setLongitudeFromString(String value);
  void swapCoordinates();
  void clear();
  void addToHistory();
  void clearHistory();
  void useHistoryEntry(CoordinatesConversionHistory entry);
  static double convertDMStoDecimal(int degrees, int minutes, int seconds, String direction);
}
```

## Tests

Tests are located in `test/widget_test.dart` under the group `CoordinatesConverter provider tests`:
- Provider existence and name verification
- Model initial values
- Latitude and longitude setting
- Coordinate clamping tests
- DMS conversion tests
- Swap coordinates functionality
- Clear functionality
- History operations (add, clear, use, max limit)
- Refresh notifyListeners
- String input parsing
- Widget rendering tests
- Provider list inclusion check

## Integration

### data.dart
- Import: `import 'package:new_launcher/providers/provider_coordinates.dart';`
- Provider List: `providerCoordinatesConverter` added to `Global.providerList`

### main.dart
- Import: `import 'package:new_launcher/providers/provider_coordinates.dart';`
- MultiProvider: `ChangeNotifierProvider.value(value: coordinatesConverterModel)` added

## Future Enhancements

Potential future additions:
- UTM (Universal Transverse Mercator) coordinate format
- MGRS (Military Grid Reference System) format
- Copy coordinates to clipboard
- Parse coordinates from clipboard
- Map integration for visual coordinate display
- Reverse geocoding (coordinates to address name)